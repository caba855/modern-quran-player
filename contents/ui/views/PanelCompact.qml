import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "../core" as Core

// Compact representation for panels: the Quran-on-stand icon, sized to fill
// the panel thickness (the artwork is wider than tall, so the slot is
// widened to match instead of shrinking the icon into a square).
// While audio plays a small animated equalizer badge appears on the icon.
// Clicking it opens / closes the popup; it never toggles playback.
Item {
    id: root

    required property PlasmoidItem plasmoidItem

    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    // 306 x 213 px artwork.
    readonly property real aspect: 306 / 213
    readonly property int margin: 1

    implicitWidth: Math.round(Kirigami.Units.iconSizes.medium * aspect)
    implicitHeight: Kirigami.Units.iconSizes.medium

    Layout.minimumWidth: verticalPanel ? 0 : Math.round(height * aspect)
    Layout.preferredWidth: verticalPanel ? -1 : Math.round(height * aspect)
    Layout.minimumHeight: verticalPanel ? Math.round(width / aspect) : 0
    Layout.preferredHeight: verticalPanel ? Math.round(width / aspect) : -1

    Image {
        id: icon
        // 90% of the slot (10% smaller than edge-to-edge), centered.
        anchors.centerIn: parent
        width: Math.round((root.width - 2 * root.margin) * 0.70)
        height: Math.round((root.height - 2 * root.margin) * 0.70)
        source: Qt.resolvedUrl("../images/quran-icon.png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        sourceSize.width: 306
        sourceSize.height: 213
    }

    // "Now playing" signal: round emerald badge with three bouncing bars.
    Rectangle {
        id: badge
        visible: Core.Engine.isPlaying
        readonly property int size: Math.max(11, Math.round(Math.min(root.width, root.height) * 0.46))

        width: size
        height: size
        radius: size / 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: Core.Theme.emeraldDeep
        border.color: Core.Theme.goldColor
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: Math.max(1, Math.round(badge.size * 0.07))

            Repeater {
                model: 3

                Item {
                    id: slot
                    required property int index
                    readonly property real full: badge.size * 0.46
                    width: Math.max(2, Math.round(badge.size * 0.15))
                    height: full

                    Rectangle {
                        id: bar
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: slot.full * 0.35
                        radius: width / 2
                        color: "white"

                        SequentialAnimation on height {
                            running: badge.visible
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: slot.full * 0.3
                                to: slot.full
                                duration: 320 + slot.index * 120
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from: slot.full
                                to: slot.full * 0.3
                                duration: 320 + slot.index * 120
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.plasmoidItem.expanded = !root.plasmoidItem.expanded
    }
}
