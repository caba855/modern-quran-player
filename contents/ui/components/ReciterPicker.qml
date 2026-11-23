import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../core" as Core

// Reciter selection: a ComboBox over the catalog with a refresh action and a
// short provider-status caption (online / offline fallback).
ColumnLayout {
    id: picker

    spacing: Kirigami.Units.smallSpacing

    readonly property int selectedIndex: {
        var list = Core.Library.reciters
        for (var i = 0; i < list.length; i += 1) {
            if (list[i] && list[i].id === Core.Session.selectedReciterId) {
                return i
            }
        }
        return 0
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Label {
            text: i18n("Reciter")
            color: Core.Theme.secondaryTextColor
        }

        ComboBox {
            id: reciterCombo
            Layout.fillWidth: true
            model: Core.Library.reciters
            textRole: "name"
            valueRole: "id"
            currentIndex: picker.selectedIndex
            enabled: count > 0

            onActivated: function(index) {
                if (index >= 0 && index < count) {
                    Core.Session.setReciterId(valueAt(index))
                }
            }
        }

        ToolButton {
            icon.name: "view-refresh"
            display: AbstractButton.IconOnly
            enabled: !Core.Library.loading
            onClicked: Core.Library.refresh()

            Accessible.name: i18n("Refresh reciters")
            ToolTip.text: i18n("Refresh reciters")
            ToolTip.delay: 500
        }
    }

    Label {
        Layout.fillWidth: true
        visible: text !== ""
        text: Core.Library.statusMessage
        font: Core.Theme.smallFont
        color: Core.Library.networkMode === "online"
            ? Core.Theme.secondaryTextColor
            : Core.Theme.neutralColor
        elide: Text.ElideRight
    }
}
