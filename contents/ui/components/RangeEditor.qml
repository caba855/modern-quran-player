import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../js/services/PlaybackController.js" as PlaybackController
import "../../js/data/SurahMeta.js" as SurahMeta
import "../core" as Core

// Playback mode (ayah range / full surah) and the from–to ayah range editor.
ColumnLayout {
    id: editor

    spacing: Kirigami.Units.smallSpacing

    readonly property bool rangeMode: Core.Session.playbackMode === PlaybackController.PLAYBACK_RANGE
    readonly property int ayahCount: SurahMeta.ayahCount(Core.Session.selectedSurah)

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Label {
            text: i18n("Mode")
            color: Core.Theme.secondaryTextColor
        }

        ComboBox {
            id: modeCombo
            Layout.fillWidth: true
            model: [i18n("Ayah range"), i18n("Full surah")]
            currentIndex: Core.Session.playbackMode

            onActivated: function(index) {
                Core.Session.setPlaybackMode(index)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        enabled: editor.rangeMode
        opacity: editor.rangeMode ? 1.0 : 0.5

        Label {
            text: i18n("From")
            color: Core.Theme.secondaryTextColor
        }

        SpinBox {
            id: fromSpin
            Layout.fillWidth: true
            from: 1
            to: Math.max(1, editor.ayahCount)
            value: Core.Session.startAyah
            editable: true

            onValueModified: Core.Session.setRange(fromSpin.value, Core.Session.endAyah)
        }

        Label {
            text: i18n("to")
            color: Core.Theme.secondaryTextColor
        }

        SpinBox {
            id: toSpin
            Layout.fillWidth: true
            from: 1
            to: Math.max(1, editor.ayahCount)
            value: Core.Session.endAyah
            editable: true

            onValueModified: Core.Session.setRange(Core.Session.startAyah, toSpin.value)
        }
    }
}
