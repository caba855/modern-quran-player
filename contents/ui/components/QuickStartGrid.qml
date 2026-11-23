import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../js/data/SurahMeta.js" as SurahMeta
import "../core" as Core

// Quick-start tiles for frequently listened surahs; each builds a full-surah
// queue and plays immediately.
ColumnLayout {
    id: grid

    spacing: Kirigami.Units.smallSpacing

    // Frequently listened surahs (number, reason people return to them).
    readonly property var quickSurahs: [1, 18, 36, 55, 56, 67]
    // Responsive column count (2 on narrow layouts, 3 otherwise).
    property int columns: 3

    Kirigami.Heading {
        level: 5
        text: i18n("Quick Start")
    }

    GridLayout {
        Layout.fillWidth: true
        columns: grid.columns
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Repeater {
            model: grid.quickSurahs

            Button {
                id: quickButton
                required property int modelData
                Layout.fillWidth: true
                text: SurahMeta.label(modelData, Core.Session.uiLocale)
                onClicked: Core.Playback.quickSurah(modelData, true)
            }
        }
    }
}
