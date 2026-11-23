import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

import "../core" as Core

// Round transport button. `primary` = emerald disc with a gold ring.
Item {
    id: button

    property string iconName: ""
    property int diameter: Kirigami.Units.gridUnit * 2.2
    property bool primary: false
    property string tip: ""
    signal clicked

    implicitWidth: diameter
    implicitHeight: diameter
    opacity: enabled ? 1.0 : 0.4
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: button.tip
    Keys.onSpacePressed: button.clicked()
    Keys.onReturnPressed: button.clicked()

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: button.primary
            ? (mouse.pressed ? Core.Theme.emeraldDeep : Core.Theme.emeraldColor)
            : (mouse.containsMouse ? Core.Theme.goldFaint : "transparent")
        border.width: button.primary ? 2 : 1
        border.color: button.primary ? Core.Theme.goldColor
            : (button.activeFocus ? Core.Theme.focusRingColor : Core.Theme.goldSoft)
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: button.diameter * 0.46
        height: width
        source: button.iconName
        isMask: true
        color: button.primary ? "white" : Kirigami.Theme.textColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }

    ToolTip.text: button.tip
    ToolTip.visible: mouse.containsMouse && button.tip !== ""
    ToolTip.delay: 500
}
