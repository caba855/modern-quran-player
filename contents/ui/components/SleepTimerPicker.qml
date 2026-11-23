import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../core" as Core

// Sleep timer control: pick a duration (or Off); a caption shows the live
// countdown.
ColumnLayout {
    id: picker

    spacing: Kirigami.Units.smallSpacing

    readonly property var bucketValues: [0, 15, 30, 45, 60]
    readonly property int currentBucket: {
        var remaining = Core.SleepTimer.remainingMinutes
        for (var i = 0; i < bucketValues.length; i += 1) {
            if (bucketValues[i] === remaining) {
                return i
            }
        }
        return 0
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Label {
            text: i18n("Sleep timer")
            color: Core.Theme.secondaryTextColor
        }

        ComboBox {
            id: sleepCombo
            Layout.fillWidth: true
            model: [
                i18n("Off"),
                i18n("15 min"),
                i18n("30 min"),
                i18n("45 min"),
                i18n("60 min")
            ]
            currentIndex: picker.currentBucket

            onActivated: function(index) {
                Core.SleepTimer.set(picker.bucketValues[index])
            }
        }
    }

    Label {
        Layout.fillWidth: true
        visible: Core.SleepTimer.active
        text: i18n("%1 min remaining", Core.SleepTimer.remainingMinutes)
        font: Core.Theme.smallFont
        color: Core.Theme.neutralColor
        elide: Text.ElideRight
    }
}
