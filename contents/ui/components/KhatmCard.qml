import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../js/data/SurahMeta.js" as SurahMeta
import "../core" as Core

// Khatm progress: a ring showing how many of the 114 surahs have been
// listened through, with reset actions.
ColumnLayout {
    id: card

    spacing: Kirigami.Units.smallSpacing

    readonly property var completedSurahs: {
        var keys = Object.keys(Core.Khatm.completedMap)
        var nums = []
        for (var i = 0; i < keys.length; i += 1) {
            nums.push(parseInt(keys[i], 10))
        }
        nums.sort(function(a, b) { return a - b })
        return nums
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        ProgressRing {
            Layout.preferredWidth: Kirigami.Units.iconSizes.large
            Layout.preferredHeight: Kirigami.Units.iconSizes.large
            size: Kirigami.Units.iconSizes.large
            progress: Core.Khatm.progressRatio
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Kirigami.Heading {
                level: 5
                text: i18n("Khatm Progress")
            }

            Label {
                text: i18n("%1 of %2 surahs listened", Core.Khatm.completedCount, Core.Khatm.total)
                color: Core.Theme.secondaryTextColor
            }
        }

        ToolButton {
            icon.name: "overflow-menu"
            display: AbstractButton.IconOnly
            onClicked: resetMenu.open()

            Accessible.name: i18n("Reset options")
            ToolTip.text: i18n("Reset options")
            ToolTip.delay: 500

            Menu {
                id: resetMenu

                MenuItem {
                    text: i18n("Reset all progress…")
                    icon.name: "edit-clear"
                    enabled: Core.Khatm.completedCount > 0
                    onTriggered: confirmResetAll.open()
                }

                MenuSeparator {
                    visible: card.completedSurahs.length > 0
                }

                Instantiator {
                    model: card.completedSurahs
                    delegate: MenuItem {
                        required property var modelData
                        text: i18n("Reset %1", SurahMeta.label(modelData, Core.Session.uiLocale))
                        onTriggered: Core.Khatm.resetSurah(modelData)
                    }
                    onObjectAdded: (index, object) => resetMenu.insertItem(index + 2, object)
                    onObjectRemoved: (index, object) => resetMenu.removeItem(object)
                }
            }
        }
    }

    Dialog {
        id: confirmResetAll
        title: i18n("Reset all khatm progress?")
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        Label {
            text: i18n("This clears the listened state for all %1 surahs. This cannot be undone.", Core.Khatm.total)
            wrapMode: Text.WordWrap
        }

        onAccepted: Core.Khatm.resetAll()
    }
}
