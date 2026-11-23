import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../js/services/Labels.js" as Labels
import "../core" as Core

// The up-next queue: native item delegates with a playing indicator, click to
// play, and a hover delete action. Bounded height so the page stays compact.
ColumnLayout {
    id: queue

    spacing: Kirigami.Units.smallSpacing

    readonly property int rowHeight: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            level: 5
            text: i18n("Up Next")
        }

        Item {
            Layout.fillWidth: true
        }

        Label {
            text: Core.Playback.queuePositionLabel
            visible: text !== ""
            font: Core.Theme.smallFont
            color: Core.Theme.secondaryTextColor
        }
    }

    ListView {
        id: queueList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(queue.rowHeight * 5.5, contentHeight)
        visible: count > 0
        clip: true
        model: Core.QueueStore.queueModel
        keyNavigationEnabled: true
        boundsBehavior: Flickable.StopAtBounds

        delegate: ItemDelegate {
            id: rowDelegate
            required property int index
            required property var model
            width: queueList.width
            highlighted: index === Core.QueueStore.currentIndex

            readonly property bool isCurrentPlaying: index === Core.QueueStore.currentIndex
                && Core.Playback.isPlaying

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small

                    Label {
                        anchors.centerIn: parent
                        visible: !rowDelegate.isCurrentPlaying
                        text: rowDelegate.index + 1
                        color: Core.Theme.secondaryTextColor
                    }

                    PlayingIndicator {
                        anchors.centerIn: parent
                        visible: rowDelegate.isCurrentPlaying
                        playing: rowDelegate.isCurrentPlaying
                        height: Kirigami.Units.iconSizes.small
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        Layout.fillWidth: true
                        text: Labels.trackLabel(rowDelegate.model, Core.Session.uiLocale)
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: String(rowDelegate.model.reciterName || "")
                        font: Core.Theme.smallFont
                        color: Core.Theme.secondaryTextColor
                        elide: Text.ElideRight
                    }
                }

                ToolButton {
                    icon.name: "list-remove"
                    display: AbstractButton.IconOnly
                    opacity: rowDelegate.hovered || rowDelegate.highlighted ? 1 : 0
                    onClicked: Core.Playback.removeQueueItem(rowDelegate.model.trackId)

                    Accessible.name: i18n("Remove from queue")
                    ToolTip.text: i18n("Remove")
                    ToolTip.delay: 500
                }
            }

            onClicked: Core.Playback.playIndex(rowDelegate.index)
        }
    }

    // Empty state.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        visible: Core.QueueStore.empty

        Label {
            Layout.fillWidth: true
            text: i18n("Queue is empty")
            color: Core.Theme.secondaryTextColor
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.smallSpacing

            Button {
                text: i18n("Build Queue")
                onClicked: Core.Playback.buildQueue(false)
            }

            Button {
                text: i18n("Play Now")
                highlighted: true
                onClicked: Core.Playback.buildQueue(true)
            }
        }
    }
}
