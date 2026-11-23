import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

import "../core" as Core

// The single status surface of the widget (v1 shipped 2.5 copies).
// - info/error render as a native Kirigami.InlineMessage with retry and
//   fallback actions on errors;
// - loading renders as a calm progress row with a delayed spinner, so quick
//   operations never flicker a busy indicator.
ColumnLayout {
    id: banner

    spacing: Kirigami.Units.smallSpacing

    readonly property bool showInline: !Core.Status.busy && Core.Status.bannerVisible

    Kirigami.InlineMessage {
        id: inlineMessage
        Layout.fillWidth: true
        visible: banner.showInline
        type: Core.Status.hasError ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
        text: Core.Status.message

        actions: [
            Kirigami.Action {
                icon.name: "view-refresh"
                text: i18n("Retry")
                visible: Core.Status.hasError
                onTriggered: Core.Status.retryRequested()
            },
            Kirigami.Action {
                icon.name: "network-offline"
                text: i18n("Use offline reciters")
                visible: Core.Status.hasError && Core.Status.code === "provider"
                onTriggered: Core.Status.fallbackRequested()
            }
        ]
    }

    RowLayout {
        Layout.fillWidth: true
        visible: Core.Status.busy && Core.Status.message !== ""
        spacing: Kirigami.Units.smallSpacing

        BusyIndicator {
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            running: parent.visible
            visible: Core.Status.spinnerVisible
        }

        Label {
            Layout.fillWidth: true
            text: Core.Status.message
            elide: Text.ElideRight
            opacity: 0.8
        }
    }

    ProgressBar {
        Layout.fillWidth: true
        visible: Core.Status.busy && Core.Status.progress > 0
        value: Core.Status.progress / 100
    }

    Label {
        Layout.fillWidth: true
        visible: Core.Status.busy && Core.Status.slowHintVisible
        text: i18n("This is taking longer than usual — a slow network or the provider may be at fault.")
        wrapMode: Text.WordWrap
        font: Core.Theme.smallFont
        opacity: 0.7
    }
}
