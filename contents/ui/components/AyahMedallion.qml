import QtQuick
import QtQuick.Controls

import "../core" as Core

// Eight-point-star verse-end medallion (two overlaid squares) with the
// ayah number in Arabic-Indic digits.
Item {
    id: medallion

    property string label: ""
    readonly property int size: 34

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.centerIn: parent
        width: medallion.size * 0.68
        height: width
        color: Core.Theme.goldFaint
        border.color: Core.Theme.goldColor
        border.width: 1
    }
    Rectangle {
        anchors.centerIn: parent
        width: medallion.size * 0.68
        height: width
        rotation: 45
        color: Core.Theme.goldFaint
        border.color: Core.Theme.goldColor
        border.width: 1
    }
    Label {
        anchors.centerIn: parent
        text: medallion.label
        font.bold: true
        font.pointSize: Core.Theme.captionPointSize
        color: Core.Theme.textColor
    }
}
