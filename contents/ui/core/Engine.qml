pragma Singleton

import QtQuick
import QtMultimedia
import "../../js/services/PlaybackController.js" as PlaybackController

// Audio mechanics only: MediaPlayer lifecycle, track/seek retry policies and
// A-B loop enforcement. No queue, provider, status or persistence knowledge —
// Playback drives this object and reacts to its signals.
Item {
    id: engine

    signal endOfMedia
    signal mediaLoaded
    signal loadFailed(string errorString)
    signal seekFailed

    // What is currently loaded (set by load()).
    property string trackId: ""
    property url currentUrl: ""

    readonly property bool isPlaying: player.playbackState === MediaPlayer.PlayingState
    readonly property bool isPaused: player.playbackState === MediaPlayer.PausedState
    readonly property bool isActive: player.playbackState === MediaPlayer.PlayingState
        || player.playbackState === MediaPlayer.PausedState
    readonly property int positionMs: Math.max(0, player.position)
    readonly property int durationMs: Math.max(0, player.duration)
    readonly property bool seekable: player.seekable
    readonly property url loadedSource: player.source

    property real rate: 1.0
    property real volume: 0.85

    // A-B loop: state is persisted by Session, values are bound here by
    // Playback, enforcement happens in onPositionChanged below.
    property bool abLoopEnabled: false
    property int abStartMs: -1
    property int abEndMs: -1

    property int retryCount: 0
    property string retryTrackId: ""
    property int pendingSeekMs: -1
    property int pendingSeekAttempts: 0

    MediaPlayer {
        id: player
        audioOutput: AudioOutput {
            volume: engine.volume
        }
        playbackRate: engine.rate

        onMediaStatusChanged: function(mediaStatus) {
            if (mediaStatus === MediaPlayer.EndOfMedia) {
                engine.endOfMedia()
            }
            if (mediaStatus === MediaPlayer.BufferedMedia || mediaStatus === MediaPlayer.LoadedMedia) {
                engine.retryCount = 0
                engine.retryTrackId = ""
                engine.mediaLoaded()
            }
        }

        onErrorOccurred: function(error, errorString) {
            engine.handlePlayerError(errorString)
        }

        onPositionChanged: function(position) {
            engine.checkPendingSeek(position)
            if (PlaybackController.shouldJumpToAB(engine.abLoopEnabled, engine.abStartMs, engine.abEndMs, position)) {
                player.position = engine.abStartMs
                player.play()
            }
        }
    }

    Timer {
        id: retryTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (engine.retryTrackId !== engine.trackId || engine.currentUrl === "") {
                return
            }
            engine.reload()
        }
    }

    Timer {
        id: seekRetryTimer
        interval: 180
        repeat: true
        onTriggered: {
            if (engine.pendingSeekMs < 0) {
                stop()
                return
            }
            engine.pendingSeekAttempts += 1
            player.position = engine.pendingSeekMs
            if (engine.pendingSeekAttempts >= 3) {
                stop()
                if (Math.abs(player.position - engine.pendingSeekMs) > 1200) {
                    engine.seekFailed()
                }
                engine.pendingSeekMs = -1
                engine.pendingSeekAttempts = 0
            }
        }
    }

    function load(url, newTrackId, autoPlay) {
        currentUrl = url
        trackId = newTrackId || ""
        retryCount = 0
        retryTrackId = ""
        pendingSeekMs = -1
        pendingSeekAttempts = 0
        seekRetryTimer.stop()
        player.source = url
        if (autoPlay) {
            player.play()
        }
    }

    function reload() {
        if (currentUrl === "") {
            return
        }
        player.source = currentUrl
        player.play()
    }

    function play() {
        player.play()
    }

    function pause() {
        player.pause()
    }

    function stop() {
        player.stop()
        pendingSeekMs = -1
        pendingSeekAttempts = 0
        seekRetryTimer.stop()
    }

    function togglePlayPause() {
        if (isPlaying) {
            player.pause()
        } else {
            player.play()
        }
    }

    // Seek with verification: some streams ignore the first position write,
    // so the position is re-asserted up to three times (v1 behavior).
    function seek(ms) {
        if (currentUrl === "") {
            return false
        }
        var targetMs = ms
        if (durationMs > 0) {
            targetMs = Math.max(0, Math.min(ms, durationMs))
        } else {
            targetMs = Math.max(0, ms)
        }
        pendingSeekMs = targetMs
        pendingSeekAttempts = 0
        player.position = targetMs
        seekRetryTimer.restart()
        return true
    }

    function checkPendingSeek(position) {
        if (pendingSeekMs >= 0 && Math.abs(position - pendingSeekMs) < 700) {
            pendingSeekMs = -1
            pendingSeekAttempts = 0
            seekRetryTimer.stop()
        }
    }

    // One automatic retry per track; the second failure is reported upstream.
    function handlePlayerError(errorString) {
        if (trackId === "") {
            loadFailed(errorString)
            return
        }
        if (retryTrackId === trackId && retryCount >= 1) {
            retryCount = 0
            retryTrackId = ""
            loadFailed(errorString)
            return
        }
        retryTrackId = trackId
        retryCount += 1
        retryTimer.restart()
    }

    // Called by Playback when it moves to a different track or queue.
    function resetTransientState() {
        retryCount = 0
        retryTrackId = ""
        pendingSeekMs = -1
        pendingSeekAttempts = 0
        seekRetryTimer.stop()
        retryTimer.stop()
    }
}
