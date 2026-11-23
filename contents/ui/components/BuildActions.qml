import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../core" as Core

// Build Queue / Play Now actions plus a thin build-progress bar.
ColumnLayout {
    id: actions

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Button {
            Layout.fillWidth: true
            text: i18n("Build Queue")
            icon.name: "media-playlist-append"
            enabled: !Core.Playback.isQueueLoading
            onClicked: Core.Playback.buildQueue(false)
        }

        Button {
            Layout.fillWidth: true
            text: i18n("Play Now")
            icon.name: "media-playback-start"
            highlighted: true
            enabled: !Core.Playback.isQueueLoading
            onClicked: Core.Playback.buildQueue(true)
        }
    }

    ProgressBar {
        Layout.fillWidth: true
        visible: Core.Playback.isQueueLoading
        indeterminate: Core.Status.progress <= 0
        value: Core.Status.progress / 100
    }
}
