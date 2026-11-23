import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../js/data/SurahMeta.js" as SurahMeta
import "../core" as Core

// Surah selection: a button showing the current surah that opens a browsable,
// searchable popup list of all 114 surahs.
ColumnLayout {
    id: picker

    spacing: Kirigami.Units.smallSpacing

    readonly property var allSurahs: SurahMeta.list()
    readonly property var filteredSurahs: {
        var filter = searchField.text.trim().toLowerCase()
        if (filter.length === 0) {
            return allSurahs
        }
        var result = []
        for (var i = 0; i < allSurahs.length; i += 1) {
            var s = allSurahs[i]
            if (String(s.number) === filter
                || s.nameEn.toLowerCase().indexOf(filter) !== -1
                || s.nameAr.indexOf(searchField.text.trim()) !== -1) {
                result.push(s)
            }
        }
        return result
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Label {
            text: i18n("Surah")
            color: Core.Theme.secondaryTextColor
        }

        Button {
            id: surahButton
            Layout.fillWidth: true
            text: SurahMeta.label(Core.Session.selectedSurah, Core.Session.uiLocale)
            onClicked: surahPopup.open()
            Accessible.name: i18n("Choose surah")
        }
    }

    Popup {
        id: surahPopup
        // No explicit parent: QQC2 attaches the popup to the window overlay
        // when opened. The guards keep load-time evaluation safe (the overlay
        // does not exist yet inside a plasmoid until a popup is shown).
        x: parent ? Math.round((parent.width - width) / 2) : 0
        y: parent ? Math.round((parent.height - height) / 2) : 0
        width: Math.round(Kirigami.Units.gridUnit * 22)
        height: Math.round(Kirigami.Units.gridUnit * 24)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.SearchField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: i18n("Search surah…")
                focus: true
            }

            ListView {
                id: surahList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: picker.filteredSurahs
                keyNavigationEnabled: true

                delegate: ItemDelegate {
                    id: surahDelegate
                    required property var model
                    width: surahList.width
                    highlighted: model.number === Core.Session.selectedSurah

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Label {
                            text: model.number + "."
                            color: Core.Theme.secondaryTextColor
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                text: model.nameEn
                                elide: Text.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                text: model.nameAr + "  ·  " + model.ayahCount + " " + i18n("ayahs")
                                font: Core.Theme.smallFont
                                color: Core.Theme.secondaryTextColor
                                elide: Text.ElideRight
                            }
                        }

                        Kirigami.Icon {
                            source: "dialog-ok"
                            visible: Core.Khatm.isCompleted(model.number)
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            color: Core.Theme.positiveColor
                        }
                    }

                    onClicked: {
                        Core.Session.setSurah(model.number)
                        surahPopup.close()
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: surahList.count === 0
                    text: i18n("No matching surah")
                    color: Core.Theme.secondaryTextColor
                }
            }
        }
    }
}
