import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../js/services/Labels.js" as Labels
import "../../js/data/SurahMeta.js" as SurahMeta
import "../core" as Core

// A single generic list used for both bookmarks and presets (kind selects
// which). Click applies/jumps; a hover delete removes; presets get a
// save-current action.
ColumnLayout {
    id: list

    spacing: Kirigami.Units.smallSpacing

    // "bookmarks" | "presets"
    property string kind: "bookmarks"

    readonly property bool isBookmarks: kind === "bookmarks"
    readonly property var items: isBookmarks ? Core.Collection.bookmarks : Core.Collection.presets

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            level: 5
            text: list.isBookmarks ? i18n("Bookmarks") : i18n("Presets")
        }

        Item {
            Layout.fillWidth: true
        }

        Button {
            visible: !list.isBookmarks
            text: i18n("Save current")
            icon.name: "document-save"
            onClicked: Core.Collection.savePreset("")
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        visible: list.items.length === 0

        Label {
            Layout.fillWidth: true
            text: list.isBookmarks
                ? i18n("No bookmarks yet — press Ctrl+B while playing to save a position.")
                : i18n("No presets yet — save your current settings to reuse them.")
            color: Core.Theme.secondaryTextColor
            wrapMode: Text.WordWrap
        }
    }

    Repeater {
        model: list.items

        ItemDelegate {
            id: itemDelegate
            required property var model
            Layout.fillWidth: true

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: list.isBookmarks ? "bookmarks" : "document-save"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    color: Core.Theme.secondaryTextColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        Layout.fillWidth: true
                        text: itemDelegate.model.label || ""
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: list.subtitleFor(itemDelegate.model)
                        font: Core.Theme.smallFont
                        color: Core.Theme.secondaryTextColor
                        elide: Text.ElideRight
                    }
                }

                ToolButton {
                    icon.name: "delete"
                    display: AbstractButton.IconOnly
                    opacity: itemDelegate.hovered ? 1 : 0
                    onClicked: list.isBookmarks
                        ? Core.Collection.removeBookmark(itemDelegate.model.id)
                        : Core.Collection.removePreset(itemDelegate.model.id)

                    Accessible.name: i18n("Delete")
                    ToolTip.text: i18n("Delete")
                    ToolTip.delay: 500
                }
            }

            onClicked: list.isBookmarks
                ? Core.Collection.jumpToBookmark(itemDelegate.model)
                : Core.Collection.applyPreset(itemDelegate.model)
        }
    }

    function subtitleFor(item) {
        if (list.isBookmarks) {
            return Labels.reciterNameById(Core.Library.reciters, item.reciterId)
        }
        var surahLabel = SurahMeta.label(item.surahNumber, Core.Session.uiLocale)
        var reciter = Labels.reciterNameById(Core.Library.reciters, item.reciterId)
        return reciter.length > 0 ? surahLabel + "  ·  " + reciter : surahLabel
    }
}
