import QtQuick
import org.kde.kirigami as Kirigami

import "../core" as Core

// A calm three-bar "now playing" indicator. Theme-colored, no hardcoded hues.
// Bars are bottom-aligned and grow upward while playing.
Item {
    id: indicator

    property bool playing: false
    property color barColor: Core.Theme.accentColor

    readonly property int barCount: 3
    readonly property int barWidth: Math.max(2, Math.round(Kirigami.Units.gridUnit / 6))
    readonly property int barSpacing: Math.max(2, Kirigami.Units.smallSpacing / 2)

    implicitWidth: barCount * barWidth + (barCount - 1) * barSpacing
    implicitHeight: Kirigami.Units.iconSizes.small

    Row {
        anchors.fill: parent

        Repeater {
            model: indicator.barCount

            Item {
                id: barCell
                required property int index
                width: indicator.barWidth
                height: indicator.height

                Rectangle {
                    id: bar
                    width: indicator.barWidth
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: indicator.playing ? indicator.height * 0.5 : indicator.height * 0.25
                    radius: width / 2
                    color: indicator.barColor
                    opacity: 0.9

                    SequentialAnimation on height {
                        running: indicator.playing
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: indicator.height * 0.25
                            to: indicator.height
                            duration: 380 + barCell.index * 110
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            from: indicator.height
                            to: indicator.height * 0.25
                            duration: 380 + barCell.index * 110
                            easing.type: Easing.InOutSine
                        }
                    }

                    Behavior on height {
                        enabled: !indicator.playing
                        NumberAnimation { duration: 150 }
                    }
                }
            }
        }
    }
}
