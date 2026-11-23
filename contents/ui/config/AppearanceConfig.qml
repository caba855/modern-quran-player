import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Popup appearance.
Kirigami.FormLayout {
    id: page

    property alias cfg_showControls: showControlsSwitch.checked
    property alias cfg_showTranslation: showTranslationSwitch.checked

    Switch {
        id: showControlsSwitch
        Kirigami.FormData.label: i18n("Side panel:")
        text: i18n("Show the Listen / Library panel beside the player")
    }

    Label {
        Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        wrapMode: Text.WordWrap
        font.italic: true
        color: Kirigami.Theme.disabledTextColor
        text: i18n("Turn off to keep only the player in the popup. The arrow button in the player header also toggles it. The same controls are on the Playback page of this dialog.")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    Switch {
        id: showTranslationSwitch
        Kirigami.FormData.label: i18n("Translation:")
        text: i18n("Show English translation under the verse")
    }

    Label {
        Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        wrapMode: Text.WordWrap
        font.italic: true
        color: Kirigami.Theme.disabledTextColor
        text: i18n("Uses the Saheeh International translation from Quran.com. The EN button in the player header also toggles it.")
    }
}
