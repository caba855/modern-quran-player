import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../js/services/PlaybackController.js" as PlaybackController
import "../core" as Core

// Hifz / memorisation tools, tucked behind a disclosure so they stay out of
// the way for casual listening: repeat mode, per-ayah repeats and A-B loop.
ColumnLayout {
    id: tools

    spacing: Kirigami.Units.smallSpacing
    property bool expanded: false

    ToolButton {
        Layout.fillWidth: true
        text: i18n("Repeat & A-B tools")
        icon.name: tools.expanded ? "arrow-down" : "arrow-right"
        display: AbstractButton.TextBesideIcon
        onClicked: tools.expanded = !tools.expanded
        Accessible.name: i18n("Toggle repeat and A-B tools")
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        visible: tools.expanded

        // Repeat mode.
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Label {
                text: i18n("Repeat")
                color: Core.Theme.secondaryTextColor
            }

            ComboBox {
                Layout.fillWidth: true
                model: [i18n("Off"), i18n("Repeat track"), i18n("Repeat queue")]
                currentIndex: Core.Session.repeatMode

                onActivated: function(index) {
                    Core.Session.setRepeatMode(index)
                }
            }
        }

        // Per-ayah repeats.
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Label {
                text: i18n("Ayah repeats")
                color: Core.Theme.secondaryTextColor
            }

            SpinBox {
                Layout.fillWidth: true
                from: 1
                to: 25
                value: Core.Session.ayahRepeatTarget
                editable: true

                onValueModified: Core.Session.setAyahRepeatTarget(value)
            }
        }

        // A-B loop.
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Button {
                text: i18n("Set A")
                enabled: Core.Playback.currentTrack !== null
                onClicked: Core.Playback.setABStart()
            }

            Button {
                text: i18n("Set B")
                enabled: Core.Playback.currentTrack !== null && Core.Session.abStartMs >= 0
                onClicked: Core.Playback.setABEnd()
            }

            Button {
                text: i18n("Clear")
                enabled: Core.Session.abLoopEnabled || Core.Session.abStartMs >= 0
                onClicked: Core.Playback.clearABLoop()
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                text: Core.Session.abLoopEnabled
                    ? i18n("Loop %1–%2",
                        PlaybackController.formatClock(Core.Session.abStartMs),
                        PlaybackController.formatClock(Core.Session.abEndMs))
                    : (Core.Session.abStartMs >= 0
                        ? i18n("A at %1", PlaybackController.formatClock(Core.Session.abStartMs))
                        : "")
                font: Core.Theme.smallFont
                color: Core.Theme.accentColor
                visible: text !== ""
            }
        }
    }
}
