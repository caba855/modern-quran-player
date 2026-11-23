pragma Singleton

import QtQuick
import "../../js/services/ProviderQuranCom.js" as ProviderQuranCom
import "../../js/services/PlaybackController.js" as PlaybackController
import "../../js/services/Labels.js" as Labels
import "../../js/data/SurahMeta.js" as SurahMeta

// The conductor: transport, queue building, MPRIS and session snapshots.
//
// Playback owns no audio state of its own — Engine plays, QueueStore holds
// the list, Session persists preferences, Status reports, Library provides the
// reciter, Verse provides ayah text. Playback wires them together and exposes
// intent functions the views call.
Item {
    id: playback

    // Emitted when a queue that covered a whole surah finishes; the khatm
    // tracker listens to this.
    signal queueCompleted(int surahNumber, bool wasFullScope)

    property bool isQueueLoading: false
    property int ayahRepeatCounter: 1
    // Position to jump to once the next media load completes (session restore).
    property int pendingRestoreMs: -1

    readonly property bool isPlaying: Engine.isPlaying
    readonly property var currentTrack: QueueStore.currentTrack
    readonly property bool canGoNext: !QueueStore.empty
        && (QueueStore.currentIndex + 1 < QueueStore.count
            || Session.repeatMode !== PlaybackController.REPEAT_NONE)
    readonly property bool canGoPrevious: !QueueStore.empty
    readonly property string currentTrackLabel: currentTrack
        ? Labels.trackLabel(currentTrack, Session.uiLocale)
        : i18n("No track")
    readonly property string queuePositionLabel: Labels.queuePositionLabel(QueueStore.currentIndex, QueueStore.count)

    // ---- Engine follows Session-owned parameters --------------------------
    Binding { target: Engine; property: "rate"; value: Session.speed; restoreMode: Binding.RestoreNone }
    Binding { target: Engine; property: "volume"; value: Session.volume; restoreMode: Binding.RestoreNone }
    Binding { target: Engine; property: "abLoopEnabled"; value: Session.abLoopEnabled; restoreMode: Binding.RestoreNone }
    Binding { target: Engine; property: "abStartMs"; value: Session.abStartMs; restoreMode: Binding.RestoreNone }
    Binding { target: Engine; property: "abEndMs"; value: Session.abEndMs; restoreMode: Binding.RestoreNone }

    // ---- MPRIS (optional C++ plugin) --------------------------------------
    Loader {
        id: mprisLoader
        source: "../components/MprisBridge.qml"
        asynchronous: true
        onStatusChanged: {
            if (status === Loader.Error) {
                console.log("QuranPlayer: MPRIS plugin not available, media keys disabled")
            } else if (status === Loader.Ready && item) {
                item.manager = playback
                playback.updateMprisStatus()
                playback.updateMprisMetadata()
            }
        }
    }
    readonly property var mprisManager: mprisLoader.status === Loader.Ready ? mprisLoader.item : null

    // ---- Wiring ------------------------------------------------------------
    Connections {
        target: Engine
        function onEndOfMedia() { playback.onTrackEnded() }
        function onLoadFailed(errorString) { playback.handleLoadFailed(errorString) }
        function onSeekFailed() { Status.setError(i18n("Could not seek this stream right now"), "playback") }
        function onMediaLoaded() { playback.updateMprisStatus() }
        function onDurationMsChanged() { playback.updateMprisMetadata() }
        function onIsPlayingChanged() { playback.updateMprisStatus() }
    }

    Connections {
        target: Session
        // Changing what would be queued invalidates the current queue.
        function onSelectionChanged() { QueueStore.clear(); playback.ayahRepeatCounter = 1 }
    }

    Connections {
        target: Status
        function onRetryRequested() { playback.retryLastAction() }
        function onFallbackRequested() { playback.fallbackToCurated() }
    }

    // Periodic session snapshot while playing (restored by the Continue card).
    Timer {
        id: sessionSnapshotTimer
        interval: 10000
        repeat: true
        running: Engine.isPlaying
        onTriggered: playback.saveSessionSnapshot()
    }

    // ---- Queue building ----------------------------------------------------
    function requestBuildQueue(params) {
        var config = params || {}
        if (config.reciterId) {
            Session.setReciterId(config.reciterId)
        }
        if (config.surahNumber !== undefined) {
            Session.setSurah(config.surahNumber)
        }
        if (config.startAyah !== undefined && config.endAyah !== undefined) {
            Session.setRange(config.startAyah, config.endAyah)
        }
        if (config.playbackMode !== undefined) {
            Session.setPlaybackMode(config.playbackMode)
        }
        buildQueue(config.autoPlay === true)
    }

    function buildQueue(autoPlay) {
        var reciter = Library.selectedReciter
        if (!reciter) {
            Status.setError(i18n("No reciter selected"), "provider")
            return
        }

        var surahNumber = Session.selectedSurah
        var maxAyah = SurahMeta.ayahCount(surahNumber)
        var normalized = PlaybackController.normalizeRange(Session.startAyah, Session.endAyah, maxAyah)
        if (normalized.startAyah !== Session.startAyah || normalized.endAyah !== Session.endAyah) {
            Session.setRange(normalized.startAyah, normalized.endAyah)
        }

        var isFullSurahMode = Session.playbackMode === PlaybackController.PLAYBACK_FULL_SURAH
        isQueueLoading = true
        Status.setLoading(isFullSurahMode ? i18n("Preparing full surah…") : i18n("Building queue…"), "queue-build")

        var onQueueReady = function(list) {
            isQueueLoading = false
            var tracks = annotateQueueTracks(list || [])

            QueueStore.queueSurahNumber = surahNumber
            QueueStore.queueIsFullScope = PlaybackController.isFullSurahScope(
                Session.playbackMode, Session.startAyah, Session.endAyah, maxAyah)
            QueueStore.loadQueue(tracks)
            ayahRepeatCounter = 1
            Library.resetProviderErrorStreak()

            for (var i = 0; i < tracks.length; i += 1) {
                if (tracks[i] && tracks[i].source === "fallback") {
                    Library.noteFallbackTracks()
                    break
                }
            }

            var usedFullSurahTrack = isFullSurahMode && tracks.length === 1 && tracks[0].isFullSurah
            if (isFullSurahMode && !usedFullSurahTrack) {
                Status.setInfo(i18n("Full surah unavailable, ayah queue ready"))
            } else {
                Status.setInfo(usedFullSurahTrack ? i18n("Full surah ready") : i18n("Queue ready"))
            }

            if (autoPlay && tracks.length > 0) {
                playCurrent(true)
            } else {
                prefetchUpcomingTracks()
            }
        }

        var onQueueError = function(message) {
            isQueueLoading = false
            Library.registerProviderError()
            Status.setError(i18n("Queue failed: %1", message), "provider")
        }

        var onQueueProgress = function(progressValue) {
            if (isQueueLoading && progressValue > 0 && progressValue < 100) {
                Status.tickProgress(progressValue, i18n("Building queue…") + " " + progressValue + "%")
            }
        }

        if (isFullSurahMode) {
            ProviderQuranCom.buildFullSurahQueue(reciter, surahNumber, onQueueReady, onQueueError, i18n, onQueueProgress)
        } else {
            ProviderQuranCom.buildQueueRangeOptimized(reciter, surahNumber, Session.startAyah, Session.endAyah, {
                onProgress: onQueueProgress
            }, onQueueReady, onQueueError, i18n)
        }
    }

    function annotateQueueTracks(list) {
        var tracks = list || []
        for (var i = 0; i < tracks.length; i += 1) {
            if (tracks[i] && (!tracks[i].reciterName || tracks[i].reciterName.length === 0)) {
                tracks[i].reciterName = Library.reciterNameById(tracks[i].reciterId)
                if ((!tracks[i].reciterName || tracks[i].reciterName.length === 0) && Library.selectedReciter) {
                    tracks[i].reciterName = Library.selectedReciter.name
                }
            }
        }
        return tracks
    }

    // ---- Transport ---------------------------------------------------------
    function playCurrent(resetPosition) {
        var track = QueueStore.currentTrack
        if (!track) {
            Verse.clear()
            Status.setError(i18n("No track selected"), "playback")
            return
        }
        if (resetPosition) {
            pendingRestoreMs = -1
        }

        if (track.isFullSurah) {
            Verse.clear()
            Status.setInfo(i18n("Playing full Surah %1", track.surahNumber))
        } else {
            Status.setInfo(i18n("Playing %1:%2", track.surahNumber, track.ayahNumber))
            Verse.load(track.surahNumber, track.ayahNumber)
        }

        Engine.load(track.url, track.trackId, true)
        updateMprisMetadata()
        updateMprisStatus()
        prefetchUpcomingTracks()
    }

    function requestPlay() {
        if (!QueueStore.currentTrack) {
            buildQueue(true)
            return
        }
        if (String(Engine.loadedSource) !== String(QueueStore.currentTrack.url)) {
            playCurrent(false)
            return
        }
        Engine.play()
        if (pendingRestoreMs > 0) {
            Engine.seek(pendingRestoreMs)
            pendingRestoreMs = -1
        }
        updateMprisStatus()
        Status.setInfo(i18n("Playing"))
    }

    function requestPause() {
        if (!QueueStore.currentTrack) {
            return
        }
        Engine.pause()
        updateMprisStatus()
        saveSessionSnapshot()
        Session.saveNow()
        Status.setInfo(i18n("Paused"))
    }

    function requestStop() {
        Engine.stop()
        updateMprisStatus()
        saveSessionSnapshot()
        Session.saveNow()
        Verse.clear()
        Status.setInfo(i18n("Ready"))
    }

    function requestTogglePlayPause() {
        togglePlayPause()
    }

    function togglePlayPause() {
        if (!QueueStore.currentTrack) {
            buildQueue(true)
            return
        }
        if (Engine.isPlaying) {
            requestPause()
        } else {
            requestPlay()
        }
    }

    function nextTrack() {
        if (QueueStore.empty) {
            return
        }
        var next = PlaybackController.nextIndex(QueueStore.currentIndex, QueueStore.count, Session.repeatMode)
        if (next < 0) {
            Engine.stop()
            saveSessionSnapshot()
            Session.saveNow()
            Verse.clear()
            Status.setInfo(i18n("Queue finished"))
            queueCompleted(QueueStore.queueSurahNumber, QueueStore.queueIsFullScope)
            return
        }
        QueueStore.setCurrentIndex(next)
        ayahRepeatCounter = 1
        playCurrent(true)
    }

    function previousTrack() {
        if (QueueStore.empty) {
            return
        }
        if (Engine.positionMs > 3000) {
            Engine.seek(0)
            return
        }
        var previous = PlaybackController.previousIndex(QueueStore.currentIndex, QueueStore.count)
        QueueStore.setCurrentIndex(previous)
        ayahRepeatCounter = 1
        playCurrent(true)
    }

    function playIndex(index) {
        if (index < 0 || index >= QueueStore.count) {
            return
        }
        QueueStore.setCurrentIndex(index)
        ayahRepeatCounter = 1
        playCurrent(true)
    }

    function onTrackEnded() {
        if (ayahRepeatCounter < Session.ayahRepeatTarget) {
            ayahRepeatCounter += 1
            playCurrent(true)
            return
        }
        ayahRepeatCounter = 1
        nextTrack()
    }

    function handleLoadFailed(errorString) {
        var next = PlaybackController.nextIndex(QueueStore.currentIndex, QueueStore.count, Session.repeatMode)
        if (QueueStore.count > 1 && next >= 0) {
            Status.setError(i18n("Track failed twice, skipping to next"), "playback")
            nextTrack()
        } else {
            Status.setError(i18n("Playback error: %1", errorString), "playback")
        }
    }

    function removeQueueItem(trackId) {
        var index = QueueStore.findIndexByTrackId(trackId)
        if (index < 0) {
            return
        }
        var removedCurrent = index === QueueStore.currentIndex
        QueueStore.removeTrack(index)
        if (QueueStore.empty) {
            requestStop()
            Status.setInfo(i18n("Queue is empty"))
            return
        }
        if (removedCurrent) {
            playCurrent(true)
            return
        }
        Status.setInfo(i18n("Removed from queue"))
    }

    function seek(ms) {
        Engine.seek(ms)
    }

    function setVolume(value) {
        Session.setVolume(value)
    }

    // ---- Quick actions -----------------------------------------------------
    function quickSurah(surahNumber, autoPlay) {
        var ayahCount = SurahMeta.ayahCount(surahNumber)
        if (ayahCount <= 0) {
            Status.setError(i18n("Unknown surah"), "validation")
            return
        }
        Session.setSurah(surahNumber)
        Session.setPlaybackMode(PlaybackController.PLAYBACK_FULL_SURAH)
        buildQueue(autoPlay !== false)
    }

    // ---- A-B loop (state lives in Session, enforcement in Engine) ---------
    function setABStart() {
        var pointA = Engine.positionMs
        var pointB = Session.abEndMs
        if (pointB >= 0 && pointB <= pointA) {
            pointB = -1
        }
        Session.setABLoop(Session.abLoopEnabled, pointA, pointB)
        Status.setInfo(i18n("A point set"))
    }

    function setABEnd() {
        if (Session.abStartMs < 0) {
            Status.setError(i18n("Set A point first"), "validation")
            return
        }
        var pointB = Engine.positionMs
        if (pointB <= Session.abStartMs) {
            Status.setError(i18n("B must be greater than A"), "validation")
            return
        }
        Session.setABLoop(true, Session.abStartMs, pointB)
        Status.setInfo(i18n("A-B loop enabled"))
    }

    function clearABLoop() {
        Session.clearABLoop()
        Status.setInfo(i18n("A-B loop cleared"))
    }

    // ---- Retry / fallback --------------------------------------------------
    function retryLastAction() {
        var code = Status.code
        Status.reset()
        if (code === "provider" || code === "queue-build") {
            buildQueue(false)
            return
        }
        if (code === "playback") {
            requestPlay()
        }
    }

    function fallbackToCurated() {
        Status.reset()
        Library.selectFallbackCurated()
        buildQueue(false)
    }

    // ---- Session snapshot --------------------------------------------------
    function saveSessionSnapshot() {
        if (QueueStore.empty) {
            return
        }
        Session.saveSnapshot(QueueStore.snapshot(), QueueStore.currentIndex, Engine.positionMs)
    }

    function restoreSession(snapshot) {
        var session = snapshot || Session.lastSessionSnapshot
        if (!session) {
            return
        }
        var list = session.queue || []
        if (list.length <= 0) {
            return
        }
        if (session.selectedReciterId) {
            Session.setReciterId(session.selectedReciterId)
        }
        if (session.selectedSurah) {
            Session.setSurah(session.selectedSurah)
        }
        if (session.startAyah !== undefined && session.endAyah !== undefined) {
            Session.setRange(session.startAyah, session.endAyah)
        }
        if (session.playbackMode !== undefined) {
            Session.setPlaybackMode(session.playbackMode)
        }

        var index = Math.max(0, Math.min(session.currentIndex || 0, list.length - 1))
        QueueStore.restoreFrom(list, index)
        pendingRestoreMs = Math.max(0, session.playbackPositionMs || 0)
        ayahRepeatCounter = 1

        var track = QueueStore.currentTrack
        if (track) {
            if (!track.isFullSurah) {
                Verse.load(track.surahNumber, track.ayahNumber)
            }
            Engine.load(track.url, track.trackId, false)
            updateMprisMetadata()
            updateMprisStatus()
            Status.setInfo(i18n("Session restored"))
        }
    }

    function prefetchUpcomingTracks() {
        if (QueueStore.empty) {
            return
        }
        var items = []
        var start = Math.max(0, QueueStore.currentIndex + 1)
        var end = Math.min(QueueStore.count - 1, start + 2)
        for (var i = start; i <= end; i += 1) {
            var track = QueueStore.trackAt(i)
            if (track) {
                items.push(track)
            }
        }
        ProviderQuranCom.prefetchTracks(items, 3)
    }

    // ---- MPRIS -------------------------------------------------------------
    function updateMprisStatus() {
        if (!mprisManager) {
            return
        }
        var status = "Stopped"
        if (Engine.isPlaying) {
            status = "Playing"
        } else if (Engine.isPaused) {
            status = "Paused"
        }
        mprisManager.playbackStatus = status
    }

    function updateMprisMetadata() {
        if (!mprisManager || !QueueStore.currentTrack) {
            return
        }
        var track = QueueStore.currentTrack
        var title = Labels.trackLabel(track, Session.uiLocale)
        var artist = Library.selectedReciter ? Library.selectedReciter.name : "Quran Player"
        var rawTrackId = track.trackId && track.trackId.length > 0
            ? track.trackId
            : String(QueueStore.currentIndex)
        var trackId = rawTrackId.replace(/[^A-Za-z0-9_]/g, "_")

        mprisManager.metadata = {
            "mpris:trackid": "/org/kde/quranplayer/track/" + trackId,
            "mpris:length": Math.max(0, Engine.durationMs) * 1000,
            "xesam:title": title,
            "xesam:artist": [artist],
            "xesam:album": "Quran"
        }
    }
}
