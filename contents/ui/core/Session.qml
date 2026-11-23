pragma Singleton

import QtQuick
import "../../js/services/Storage.js" as Storage
import "../../js/services/PlaybackController.js" as PlaybackController
import "../../js/data/SurahMeta.js" as SurahMeta

// Session is the single authority for user preferences and session state.
//
// - It is the ONLY object that touches Plasmoid.configuration (kcfg).
// - Runtime preferences live in kcfg; structured data (bookmarks, presets,
//   ayah cache, khatm progress, last-session snapshot) lives in SQLite via
//   Storage.js.
// - main.qml calls initialize(Plasmoid.configuration) once; everything else
//   must treat Session defaults as valid until Session.ready becomes true.
Item {
    id: session

    // Emitted once after initialize() finished; startup work (reciter
    // refresh, session restore offers) is gated on this.
    signal ready
    signal selectionChanged

    property bool initialized: false

    // Injected by main.qml; nobody else may touch it.
    property var config: null

    // ---- Preferences (mirrors contents/config/main.xml) -------------------
    property int selectedSurah: 1
    property int startAyah: 1
    property int endAyah: 7
    property string selectedReciterId: "curated:alafasy"
    property int playbackMode: PlaybackController.PLAYBACK_RANGE
    property int repeatMode: PlaybackController.REPEAT_NONE
    property int ayahRepeatTarget: 1
    readonly property real speed: 1.0
    property bool showControls: true
    property bool showTranslation: false
    property bool pinned: false
    property real volume: 0.85
    property bool abLoopEnabled: false
    property int abStartMs: -1
    property int abEndMs: -1
    property int sleepRemainingMinutes: 0

    // Last recorded listening session (queue snapshot), or null.
    property var lastSessionSnapshot: null

    readonly property string uiLocale: Qt.locale().name

    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: session.flushConfig()
    }

    function initialize(configObject) {
        if (initialized) {
            return
        }
        config = configObject
        Storage.initialize()
        migrateLegacySettings()
        loadFromConfig()
        lastSessionSnapshot = Storage.getSetting("lastSession", null)
        initialized = true
        ready()
    }

    // One-time migration: v1 stored all preferences in SQLite and never
    // touched kcfg. Copy the live keys over so the configuration dialog and
    // kcfg become the truth from v2 on.
    function migrateLegacySettings() {
        if (!config) {
            return
        }
        if (config.migratedToConfig === true) {
            return
        }
        var keys = [
            "selectedSurah", "startAyah", "endAyah", "selectedReciterId",
            "playbackMode", "repeatMode", "ayahRepeatTarget",
            "volume", "uiScale",
            "abLoopEnabled", "abStartMs", "abEndMs", "sleepRemainingMinutes"
        ]
        for (var i = 0; i < keys.length; i += 1) {
            var stored = Storage.getSetting(keys[i], null)
            if (stored !== null && stored !== undefined) {
                config[keys[i]] = stored
            }
        }
        config.migratedToConfig = true
        flushConfig()
    }

    function loadFromConfig() {
        if (!config) {
            return
        }
        selectedSurah = clampInt(config.selectedSurah, 1, 114, 1)
        startAyah = Math.max(1, config.startAyah | 0)
        endAyah = Math.max(1, config.endAyah | 0)
        selectedReciterId = String(config.selectedReciterId || "curated:alafasy")
        playbackMode = config.playbackMode | 0
        repeatMode = config.repeatMode | 0
        ayahRepeatTarget = clampInt(config.ayahRepeatTarget, 1, 25, 1)
        showControls = config.showControls !== false
        showTranslation = config.showTranslation === true
        pinned = config.pinned === true
        volume = PlaybackController.clampVolume(Number(config.volume) || 0.85)
        abLoopEnabled = config.abLoopEnabled === true
        abStartMs = config.abStartMs | 0
        abEndMs = config.abEndMs | 0
        sleepRemainingMinutes = Math.max(0, config.sleepRemainingMinutes | 0)
    }

    function clampInt(value, min, max, fallback) {
        var n = value | 0
        if (isNaN(n) || n < min || n > max) {
            return fallback
        }
        return n
    }

    // ---- Setters (normalize -> local prop -> kcfg write-through) ----------

    function setSurah(surahNumber) {
        var n = clampInt(surahNumber, 1, 114, selectedSurah)
        var rangeReset = n !== selectedSurah
        selectedSurah = n
        if (rangeReset) {
            startAyah = 1
            endAyah = SurahMeta.ayahCount(n)
            writeConfig(["selectedSurah", "startAyah", "endAyah"])
        } else {
            writeConfig(["selectedSurah"])
        }
        selectionChanged()
    }

    function setRange(fromAyah, toAyah) {
        var maxAyah = SurahMeta.ayahCount(selectedSurah)
        var normalized = PlaybackController.normalizeRange(fromAyah, toAyah, maxAyah)
        startAyah = normalized.startAyah
        endAyah = normalized.endAyah
        writeConfig(["startAyah", "endAyah"])
        selectionChanged()
    }

    function setReciterId(reciterId) {
        if (!reciterId || reciterId === selectedReciterId) {
            return
        }
        selectedReciterId = String(reciterId)
        writeConfig(["selectedReciterId"])
    }

    function setPlaybackMode(mode) {
        if (mode === playbackMode) {
            return
        }
        playbackMode = mode | 0
        writeConfig(["playbackMode"])
        selectionChanged()
    }

    function setRepeatMode(mode) {
        repeatMode = clampInt(mode, PlaybackController.REPEAT_NONE, PlaybackController.REPEAT_QUEUE, PlaybackController.REPEAT_NONE)
        writeConfig(["repeatMode"])
    }

    function setAyahRepeatTarget(count) {
        ayahRepeatTarget = clampInt(count, 1, 25, 1)
        writeConfig(["ayahRepeatTarget"])
    }

    function setShowControls(value) {
        if (!config) {
            return
        }
        config.showControls = value === true
        saveTimer.restart()
    }

    function setPinned(value) {
        pinned = value === true
        if (!config) {
            return
        }
        config.pinned = pinned
        saveTimer.restart()
    }

    function setShowTranslation(value) {
        if (!config) {
            return
        }
        config.showTranslation = value === true
        saveTimer.restart()
    }

    function setVolume(value) {
        volume = PlaybackController.clampVolume(value)
        writeConfig(["volume"])
    }

    function setABLoop(enabled, startMs, endMs) {
        abLoopEnabled = enabled === true
        abStartMs = startMs | 0
        abEndMs = endMs | 0
        writeConfig(["abLoopEnabled", "abStartMs", "abEndMs"])
    }

    function clearABLoop() {
        setABLoop(false, -1, -1)
    }

    function setSleepRemaining(minutes) {
        sleepRemainingMinutes = Math.max(0, minutes | 0)
        writeConfig(["sleepRemainingMinutes"])
    }

    // ---- Session snapshot --------------------------------------------------

    function saveSnapshot(queueList, currentIndex, positionMs) {
        var snapshot = {
            savedAt: Date.now(),
            selectedSurah: selectedSurah,
            startAyah: startAyah,
            endAyah: endAyah,
            selectedReciterId: selectedReciterId,
            playbackMode: playbackMode,
            currentIndex: currentIndex,
            playbackPositionMs: positionMs,
            queue: queueList || []
        }
        Storage.setSetting("lastSession", snapshot)
        lastSessionSnapshot = snapshot
    }

    function clearLastSession() {
        Storage.setSetting("lastSession", null)
        lastSessionSnapshot = null
    }

    // ---- Config plumbing ----------------------------------------------------

    function writeConfig(keys) {
        if (!config || !initialized) {
            return
        }
        for (var i = 0; i < keys.length; i += 1) {
            config[keys[i]] = session[keys[i]]
        }
        saveTimer.restart()
    }

    function flushConfig() {
        if (!config) {
            return
        }
        if (typeof config.save === "function") {
            config.save()
        }
    }

    function saveNow() {
        saveTimer.stop()
        flushConfig()
    }
}
