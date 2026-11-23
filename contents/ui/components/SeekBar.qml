import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../js/services/PlaybackController.js" as PlaybackController
import "../core" as Core

// Custom scrubber: emerald-to-gold progress line with a diamond handle.
// The seek is committed on release so dragging never fights live position.
ColumnLayout {
    id: seekBar

    spacing: 2
    readonly property bool seekable: Core.Engine.seekable && Core.Engine.durationMs > 0
    property bool dragging: false
    property real dragFraction: 0
    readonly property real fraction: dragging
        ? dragFraction
        : (Core.Engine.durationMs > 0
            ? Math.max(0, Math.min(1, Core.Engine.positionMs / Core.Engine.durationMs))
            : 0)

    Item {
        id: bar
        Layout.fillWidth: true
        Layout.preferredHeight: 18
        opacity: seekBar.seekable ? 1.0 : 0.6

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            height: 4
            radius: 2
            color: Core.Theme.goldFaint

            Rectangle {
                width: parent.width * seekBar.fraction
                height: parent.height
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Core.Theme.emeraldColor }
                    GradientStop { position: 1.0; color: Core.Theme.goldColor }
                }
            }
        }

        Rectangle {
            id: handle
            width: 12
            height: 12
            rotation: 45
            x: track.x + track.width * seekBar.fraction - width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Core.Theme.goldColor
            border.color: Core.Theme.emeraldDeep
            border.width: 1
            scale: area.pressed ? 1.25 : 1.0
            Behavior on scale { NumberAnimation { duration: 90 } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            enabled: seekBar.seekable
            cursorShape: Qt.PointingHandCursor

            function fractionAt(mouseX) {
                return Math.max(0, Math.min(1, (mouseX - track.x) / track.width))
            }

            onPressed: (mouse) => {
                seekBar.dragging = true
                seekBar.dragFraction = fractionAt(mouse.x)
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    seekBar.dragFraction = fractionAt(mouse.x)
                }
            }
            onReleased: {
                Core.Playback.seek(seekBar.dragFraction * Core.Engine.durationMs)
                seekBar.dragging = false
            }
            onCanceled: seekBar.dragging = false
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Label {
            text: PlaybackController.formatClock(seekBar.dragging
                ? seekBar.dragFraction * Core.Engine.durationMs
                : Core.Engine.positionMs)
            font: Core.Theme.smallFont
            color: Core.Theme.secondaryTextColor
        }

        Item {
            Layout.fillWidth: true
        }

        Label {
            text: PlaybackController.formatClock(Core.Engine.durationMs)
            font: Core.Theme.smallFont
            color: Core.Theme.secondaryTextColor
        }
    }
}
