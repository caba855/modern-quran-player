import QtQuick
import QtQuick.Layouts

import "../core" as Core

// Gold hairline - diamond - hairline divider.
RowLayout {
    id: divider

    spacing: 6
    implicitHeight: 10

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.alignment: Qt.AlignVCenter
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Core.Theme.goldClear }
            GradientStop { position: 1.0; color: Core.Theme.goldColor }
        }
    }

    Item {
        Layout.preferredWidth: 10
        Layout.preferredHeight: 10
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            anchors.centerIn: parent
            width: 7
            height: 7
            rotation: 45
            color: Core.Theme.goldColor
        }
        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 10
            rotation: 0
            color: "transparent"
            border.color: Core.Theme.goldSoft
            border.width: 1
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.alignment: Qt.AlignVCenter
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Core.Theme.goldColor }
            GradientStop { position: 1.0; color: Core.Theme.goldClear }
        }
    }
}
