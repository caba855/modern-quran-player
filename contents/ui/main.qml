import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "views" as Views
import "core" as Core

PlasmoidItem {
    id: root

    readonly property bool panelLike: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Pinned popups stay open when focus moves elsewhere.
    hideOnWindowDeactivate: !Core.Session.pinned

    toolTipMainText: Core.Playback.currentTrack ? Core.Playback.currentTrackLabel : i18n("Modern Quran Player")
    toolTipSubText: Core.Library.selectedReciter
        ? Core.Library.selectedReciter.name
        : (Core.Session.initialized ? "" : i18n("Starting…"))

    compactRepresentation: Views.PanelCompact {
        plasmoidItem: root
    }

    fullRepresentation: Views.DesktopExpanded {
        plasmoidItem: root
    }

    preferredRepresentation: panelLike ? compactRepresentation : fullRepresentation

    // Keyboard shortcuts (widget focus only).
    Shortcut {
        sequence: "Space"
        context: Qt.WidgetWithChildrenShortcut
        onActivated: Core.Playback.togglePlayPause()
    }
    Shortcut {
        sequence: "Ctrl+Right"
        context: Qt.WidgetWithChildrenShortcut
        onActivated: Core.Playback.nextTrack()
    }
    Shortcut {
        sequence: "Ctrl+Left"
        context: Qt.WidgetWithChildrenShortcut
        onActivated: Core.Playback.previousTrack()
    }
    Shortcut {
        sequence: "Ctrl+B"
        context: Qt.WidgetWithChildrenShortcut
        onActivated: Core.Collection.addBookmark()
    }

    // Live-sync the two display toggles with the configuration dialog.
    Binding {
        target: Core.Session
        property: "showControls"
        value: Plasmoid.configuration.showControls
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: Core.Session
        property: "showTranslation"
        value: Plasmoid.configuration.showTranslation
        restoreMode: Binding.RestoreNone
    }

    // ---- Bridge to the configuration dialog ----------------------------------
    // The dialog is a separate QML context (it has its own copies of the Core
    // singletons), so it sends commands through Plasmoid.configuration.cmd and
    // reads state that is mirrored back here. Format: "<id>|<name>|<args...>".
    readonly property string incomingCommand: Plasmoid.configuration.cmd
    onIncomingCommandChanged: {
        if (incomingCommand !== "" && Core.Session.initialized) {
            handleCommand(incomingCommand)
        }
    }

    function findById(list, id) {
        for (var i = 0; i < list.length; i += 1) {
            if (list[i] && String(list[i].id) === String(id)) {
                return list[i]
            }
        }
        return null
    }

    function handleCommand(text) {
        var parts = text.split("|")
        var name = parts.length > 1 ? parts[1] : ""
        var arg = parts.length > 2 ? parts[2] : ""
        switch (name) {
        case "build":
            Core.Playback.buildQueue(false)
            break
        case "play":
            Core.Playback.buildQueue(true)
            break
        case "quick":
            Core.Playback.quickSurah(parseInt(arg, 10), true)
            break
        case "reciter":
            Core.Session.setReciterId(arg)
            break
        case "surah":
            Core.Session.setSurah(parseInt(arg, 10))
            break
        case "mode":
            Core.Session.setPlaybackMode(parseInt(arg, 10))
            break
        case "range":
            Core.Session.setRange(parseInt(arg, 10), parseInt(parts[3], 10))
            break
        case "volume":
            Core.Playback.setVolume(parseFloat(arg))
            break
        case "sleep":
            Core.SleepTimer.set(parseInt(arg, 10))
            break
        case "repeat":
            Core.Session.setRepeatMode(parseInt(arg, 10))
            break
        case "ayahRepeat":
            Core.Session.setAyahRepeatTarget(parseInt(arg, 10))
            break
        case "abA":
            Core.Playback.setABStart()
            break
        case "abB":
            Core.Playback.setABEnd()
            break
        case "abClear":
            Core.Playback.clearABLoop()
            break
        case "khatmResetAll":
            Core.Khatm.resetAll()
            break
        case "presetSave":
            Core.Collection.savePreset("")
            break
        case "presetApply":
            Core.Collection.applyPreset(findById(Core.Collection.presets, arg))
            break
        case "presetRemove":
            Core.Collection.removePreset(arg)
            break
        case "bookmarkAdd":
            Core.Collection.addBookmark()
            break
        case "bookmarkJump":
            Core.Collection.jumpToBookmark(findById(Core.Collection.bookmarks, arg))
            break
        case "bookmarkRemove":
            Core.Collection.removeBookmark(arg)
            break
        default:
            console.log("ModernQuranPlayer: unknown command", name)
        }
    }

    // State mirrored for the dialog.
    readonly property string nowPlayingText: Core.Playback.currentTrack
        ? ((Core.Engine.isPlaying ? "\u25B6  " : "\u23F8  ") + Core.Playback.currentTrackLabel)
        : ""
    onNowPlayingTextChanged: Plasmoid.configuration.nowPlaying = nowPlayingText

    function publishReciters() {
        var list = Core.Library.reciters || []
        var slim = []
        for (var i = 0; i < list.length; i += 1) {
            if (list[i]) {
                slim.push({ id: list[i].id, name: list[i].name })
            }
        }
        Plasmoid.configuration.reciterListJson = JSON.stringify(slim)
    }

    function publishLibrary() {
        var done = []
        var keys = Object.keys(Core.Khatm.completedMap)
        for (var i = 0; i < keys.length; i += 1) {
            done.push(parseInt(keys[i], 10))
        }
        Plasmoid.configuration.libraryJson = JSON.stringify({
            bookmarks: Core.Collection.bookmarks,
            presets: Core.Collection.presets,
            khatm: done
        })
    }

    Connections {
        target: Core.Library
        function onRecitersChanged() {
            root.publishReciters()
        }
    }
    Connections {
        target: Core.Collection
        function onBookmarksChanged() {
            root.publishLibrary()
        }
        function onPresetsChanged() {
            root.publishLibrary()
        }
    }
    Connections {
        target: Core.Khatm
        function onChanged() {
            root.publishLibrary()
        }
    }

    Component.onCompleted: {
        Core.Session.initialize(Plasmoid.configuration)
        // Drop any command left over from a previous session.
        Plasmoid.configuration.cmd = ""
        Plasmoid.configuration.nowPlaying = nowPlayingText
    }

    Connections {
        target: Core.Session
        function onReady() {
            Core.Library.refresh()
            Core.Collection.reload()
            Core.Khatm.reload()
            root.publishLibrary()
            root.publishReciters()
        }
    }
}
