import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "../core" as Core
import "../components" as Components

// Full representation (popup / desktop widget).
//
// Layout: [ controls panel | player ]. The controls panel (status, Listen /
// Library tabs and pages) sits on the LEFT of the player and can be hidden
// (header arrow or Popup settings) so only the player remains.
//
// Resizing: Plasma 6 popups are resized by dragging their edges (or
// Alt+right-drag) within the Layout minimum/maximum declared here; Plasma
// remembers the size. Extra room goes to the verse panel and the page list.
Item {
    id: root

    required property PlasmoidItem plasmoidItem

    readonly property int pad: Kirigami.Units.largeSpacing
    readonly property bool showControls: Core.Session.showControls
    readonly property real screenW: plasmoidItem.availableScreenRect.width
    readonly property real screenH: plasmoidItem.availableScreenRect.height

    readonly property int controlsW: Math.round(21 * Kirigami.Units.gridUnit)
    readonly property int heroW: Math.round(24 * Kirigami.Units.gridUnit)
    readonly property int heroMinW: Math.round(20 * Kirigami.Units.gridUnit)
    readonly property int heroMinHeight: Math.round(hero.implicitHeight + 2 * pad)
    readonly property int sideGaps: showControls ? 3 * pad + 1 : 2 * pad

    readonly property int minW: sideGaps + heroMinW + (showControls ? controlsW : 0)
    readonly property int minH: showControls
        ? Math.max(heroMinHeight, Math.round(24 * Kirigami.Units.gridUnit))
        : heroMinHeight
    readonly property int defaultH: {
        var wanted = Math.round(34 * Kirigami.Units.gridUnit)
        var h = screenH > 0 ? Math.min(wanted, Math.round(screenH * 0.9)) : wanted
        return Math.max(minH, h)
    }

    implicitWidth: sideGaps + heroW + (showControls ? controlsW : 0)
    implicitHeight: showControls ? defaultH : heroMinHeight

    Layout.minimumWidth: minW
    Layout.minimumHeight: minH
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.maximumWidth: screenW > 0 ? Math.round(screenW * 0.95) : 2400
    Layout.maximumHeight: screenH > 0 ? Math.round(screenH * 0.95) : 1080

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.pad

        // ---- Left: status + tabs + pages -----------------------------------
        ColumnLayout {
            id: controlsPanel
            Layout.fillHeight: true
            Layout.minimumWidth: root.controlsW
            Layout.preferredWidth: root.controlsW
            Layout.maximumWidth: root.controlsW
            visible: root.showControls
            spacing: Kirigami.Units.smallSpacing

            Components.StatusBanner {
                Layout.fillWidth: true
            }

            TabBar {
                id: tabBar
                Layout.fillWidth: true

                TabButton { text: i18n("Listen") }
                TabButton { text: i18n("Library") }
            }

            ScrollView {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 6
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                // Only the active page takes part in the layout, so the
                // scroll height always matches that page.
                ColumnLayout {
                    width: scroll.availableWidth
                    spacing: 0

                    PlayerPage {
                        Layout.fillWidth: true
                        visible: tabBar.currentIndex === 0
                    }
                    LibraryPage {
                        Layout.fillWidth: true
                        visible: tabBar.currentIndex === 1
                    }
                }
            }
        }

        // Divider between the panel and the player.
        Rectangle {
            visible: root.showControls
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: Core.Theme.goldSoft
        }

        // ---- Right: the player ---------------------------------------------
        Components.NowPlayingHero {
            id: hero
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: root.heroMinW
            Layout.preferredWidth: root.heroW
        }
    }
}
