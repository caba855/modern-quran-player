import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

import "../../js/data/SurahMeta.js" as SurahMeta

// Playback page: Listen + Library + startup defaults, merged into one page.
//
// The configuration dialog is a separate QML context from the widget, so it
// cannot call the player directly. It reads the widget's live state from
// Plasmoid.configuration (the widget writes every setting through to it) and
// sends actions as commands through the `cmd` key, which the widget executes
// (see main.qml). Reciters, bookmarks, presets and khatm progress are
// mirrored by the widget as JSON in `reciterListJson` / `libraryJson`.
KCM.SimpleKCM {
    id: page

    readonly property var cfg: Plasmoid.configuration
    property int cmdCounter: 0
    property bool confirmKhatm: false
    readonly property string uiLocale: Qt.locale().name

    readonly property var reciters: parseJson(cfg.reciterListJson, [])
    readonly property var library: parseJson(cfg.libraryJson, ({}))
    readonly property var bookmarks: library.bookmarks || []
    readonly property var presets: library.presets || []
    readonly property var khatm: library.khatm || []

    readonly property var surahLabels: {
        var labels = []
        for (var i = 1; i <= 114; i += 1) {
            labels.push(SurahMeta.label(i, Qt.locale().name))
        }
        return labels
    }
    readonly property int ayahCount: Math.max(1, SurahMeta.ayahCount(cfg.selectedSurah))
    readonly property bool rangeMode: cfg.playbackMode === 0
    readonly property var sleepBuckets: [0, 15, 30, 45, 60]
    readonly property var quickSurahs: [1, 18, 36, 55, 56, 67]

    function parseJson(text, fallback) {
        if (!text || text.length === 0) {
            return fallback
        }
        try {
            return JSON.parse(text)
        } catch (e) {
            return fallback
        }
    }

    // Send a command to the running widget: send("name", arg1, arg2, ...).
    function send(name) {
        cmdCounter += 1
        var parts = [String(Date.now()) + "." + cmdCounter, name]
        for (var i = 1; i < arguments.length; i += 1) {
            parts.push(String(arguments[i]))
        }
        cfg.cmd = parts.join("|")
    }

    function reciterIndex(id) {
        for (var i = 0; i < reciters.length; i += 1) {
            if (reciters[i] && reciters[i].id === id) {
                return i
            }
        }
        return reciters.length > 0 ? 0 : -1
    }

    function reciterName(id) {
        var index = -1
        for (var i = 0; i < reciters.length; i += 1) {
            if (reciters[i] && reciters[i].id === id) {
                index = i
                break
            }
        }
        return index >= 0 ? reciters[index].name : ""
    }

    function sleepIndex(minutes) {
        for (var i = 0; i < sleepBuckets.length; i += 1) {
            if (sleepBuckets[i] === minutes) {
                return i
            }
        }
        return 0
    }

    function presetSubtitle(item) {
        var surah = SurahMeta.label(item.surahNumber || 1, uiLocale)
        var reciter = reciterName(item.reciterId)
        return reciter.length > 0 ? surah + "  ·  " + reciter : surah
    }

    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: page.confirmKhatm = false
    }

    Kirigami.FormLayout {
        id: form

        // ---- Now playing ----------------------------------------------------
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Now playing")
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            wrapMode: Text.WordWrap
            text: page.cfg.nowPlaying !== "" ? page.cfg.nowPlaying : i18n("Nothing playing yet")
        }

        // ---- Listen -----------------------------------------------------------
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Listen")
        }

        QQC2.ComboBox {
            id: reciterCombo
            Kirigami.FormData.label: i18n("Reciter:")
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            model: page.reciters
            textRole: "name"
            valueRole: "id"
            enabled: count > 0
            displayText: count > 0 ? currentText : i18n("Loading reciters…")
            onActivated: function(index) {
                if (index >= 0 && index < count) {
                    page.send("reciter", valueAt(index))
                }
            }

            Binding {
                target: reciterCombo
                property: "currentIndex"
                value: page.reciterIndex(page.cfg.selectedReciterId)
                restoreMode: Binding.RestoreNone
            }
        }

        QQC2.ComboBox {
            id: surahCombo
            Kirigami.FormData.label: i18n("Surah:")
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            model: page.surahLabels
            onActivated: function(index) {
                page.send("surah", index + 1)
            }

            Binding {
                target: surahCombo
                property: "currentIndex"
                value: page.cfg.selectedSurah - 1
                restoreMode: Binding.RestoreNone
            }
        }

        QQC2.ComboBox {
            id: modeCombo
            Kirigami.FormData.label: i18n("Mode:")
            model: [i18n("Ayah range"), i18n("Full surah")]
            onActivated: function(index) {
                page.send("mode", index)
            }

            Binding {
                target: modeCombo
                property: "currentIndex"
                value: page.cfg.playbackMode
                restoreMode: Binding.RestoreNone
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Ayah range:")
            enabled: page.rangeMode
            opacity: page.rangeMode ? 1.0 : 0.5
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: fromSpin
                from: 1
                to: page.ayahCount
                editable: true
                onValueModified: page.send("range", value, toSpin.value)

                Binding {
                    target: fromSpin
                    property: "value"
                    value: page.cfg.startAyah
                    restoreMode: Binding.RestoreNone
                }
            }

            QQC2.Label {
                text: i18n("to")
            }

            QQC2.SpinBox {
                id: toSpin
                from: 1
                to: page.ayahCount
                editable: true
                onValueModified: page.send("range", fromSpin.value, value)

                Binding {
                    target: toSpin
                    property: "value"
                    value: page.cfg.endAyah
                    restoreMode: Binding.RestoreNone
                }
            }
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Build Queue")
                icon.name: "media-playlist-append"
                onClicked: page.send("build")
            }

            QQC2.Button {
                text: i18n("Play Now")
                icon.name: "media-playback-start"
                highlighted: true
                onClicked: page.send("play")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Volume:")
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                stepSize: 0.01
                onMoved: page.send("volume", value.toFixed(2))

                Binding {
                    target: volumeSlider
                    property: "value"
                    value: page.cfg.volume
                    restoreMode: Binding.RestoreNone
                }
            }

            QQC2.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                text: Math.round(page.cfg.volume * 100) + "%"
            }
        }

        QQC2.ComboBox {
            id: sleepCombo
            Kirigami.FormData.label: i18n("Sleep timer:")
            model: [i18n("Off"), i18n("15 min"), i18n("30 min"), i18n("45 min"), i18n("60 min")]
            onActivated: function(index) {
                page.send("sleep", page.sleepBuckets[index])
            }

            Binding {
                target: sleepCombo
                property: "currentIndex"
                value: page.sleepIndex(page.cfg.sleepRemainingMinutes)
                restoreMode: Binding.RestoreNone
            }
        }

        QQC2.Label {
            visible: page.cfg.sleepRemainingMinutes > 0
            color: Kirigami.Theme.neutralTextColor
            text: i18n("%1 min remaining", page.cfg.sleepRemainingMinutes)
        }

        // ---- Repeat & A-B -------------------------------------------------
        QQC2.ComboBox {
            id: repeatCombo
            Kirigami.FormData.label: i18n("Repeat:")
            model: [i18n("Off"), i18n("Repeat track"), i18n("Repeat queue")]
            onActivated: function(index) {
                page.send("repeat", index)
            }

            Binding {
                target: repeatCombo
                property: "currentIndex"
                value: page.cfg.repeatMode
                restoreMode: Binding.RestoreNone
            }
        }

        QQC2.SpinBox {
            id: ayahRepeatSpin
            Kirigami.FormData.label: i18n("Ayah repeats:")
            from: 1
            to: 25
            editable: true
            onValueModified: page.send("ayahRepeat", value)

            Binding {
                target: ayahRepeatSpin
                property: "value"
                value: page.cfg.ayahRepeatTarget
                restoreMode: Binding.RestoreNone
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("A-B loop:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Set A")
                onClicked: page.send("abA")
            }
            QQC2.Button {
                text: i18n("Set B")
                onClicked: page.send("abB")
            }
            QQC2.Button {
                text: i18n("Clear")
                onClicked: page.send("abClear")
            }
        }

        // ---- Library: quick start ------------------------------------------------
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Library")
        }

        GridLayout {
            Kirigami.FormData.label: i18n("Quick start:")
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Repeater {
                model: page.quickSurahs

                QQC2.Button {
                    required property int modelData
                    Layout.fillWidth: true
                    text: SurahMeta.label(modelData, page.uiLocale)
                    onClicked: page.send("quick", modelData)
                }
            }
        }

        // ---- Khatm -------------------------------------------------------------------
        ColumnLayout {
            Kirigami.FormData.label: i18n("Khatm:")
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            spacing: Kirigami.Units.smallSpacing

            QQC2.ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 114
                value: page.khatm.length
            }

            RowLayout {
                Layout.fillWidth: true

                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("%1 of %2 surahs listened", page.khatm.length, 114)
                    color: Kirigami.Theme.disabledTextColor
                }

                QQC2.Button {
                    enabled: page.khatm.length > 0
                    text: page.confirmKhatm ? i18n("Click again to confirm") : i18n("Reset progress")
                    icon.name: "edit-clear"
                    onClicked: {
                        if (page.confirmKhatm) {
                            confirmTimer.stop()
                            page.confirmKhatm = false
                            page.send("khatmResetAll")
                        } else {
                            page.confirmKhatm = true
                            confirmTimer.restart()
                        }
                    }
                }
            }
        }

        // ---- Presets ------------------------------------------------------------------
        ColumnLayout {
            Kirigami.FormData.label: i18n("Presets:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Save current settings")
                icon.name: "document-save"
                onClicked: page.send("presetSave")
            }

            QQC2.Label {
                visible: page.presets.length === 0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
                text: i18n("No presets yet — save your current settings to reuse them.")
            }

            Repeater {
                model: page.presets

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: modelData.label || ""
                            elide: Text.ElideRight
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: page.presetSubtitle(modelData)
                            font: Kirigami.Theme.smallFont
                            color: Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                        }
                    }

                    QQC2.Button {
                        text: i18n("Apply")
                        onClicked: page.send("presetApply", modelData.id)
                    }
                    QQC2.ToolButton {
                        icon.name: "delete"
                        display: QQC2.AbstractButton.IconOnly
                        onClicked: page.send("presetRemove", modelData.id)
                        QQC2.ToolTip.text: i18n("Delete")
                        QQC2.ToolTip.visible: hovered
                    }
                }
            }
        }

        // ---- Bookmarks ----------------------------------------------------------------
        ColumnLayout {
            Kirigami.FormData.label: i18n("Bookmarks:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Bookmark current position")
                icon.name: "bookmark-new"
                onClicked: page.send("bookmarkAdd")
            }

            QQC2.Label {
                visible: page.bookmarks.length === 0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
                text: i18n("No bookmarks yet — bookmark a position while playing.")
            }

            Repeater {
                model: page.bookmarks

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: modelData.label || ""
                            elide: Text.ElideRight
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: page.reciterName(modelData.reciterId)
                            visible: text !== ""
                            font: Kirigami.Theme.smallFont
                            color: Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                        }
                    }

                    QQC2.Button {
                        text: i18n("Play")
                        onClicked: page.send("bookmarkJump", modelData.id)
                    }
                    QQC2.ToolButton {
                        icon.name: "delete"
                        display: QQC2.AbstractButton.IconOnly
                        onClicked: page.send("bookmarkRemove", modelData.id)
                        QQC2.ToolTip.text: i18n("Delete")
                        QQC2.ToolTip.visible: hovered
                    }
                }
            }
        }
    }
}
