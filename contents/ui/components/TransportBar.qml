import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../core" as Core

// Previous / play-pause / next with the primary action as an emerald disc.
RowLayout {
    id: transport

    spacing: Kirigami.Units.largeSpacing * 1.5

    PlayerButton {
        iconName: "media-skip-backward"
        diameter: Math.round(Kirigami.Units.gridUnit * 2.1)
        enabled: Core.Playback.canGoPrevious
        tip: i18n("Previous")
        onClicked: Core.Playback.previousTrack()
    }

    PlayerButton {
        primary: true
        iconName: Core.Engine.isPlaying ? "media-playback-pause" : "media-playback-start"
        diameter: Math.round(Kirigami.Units.gridUnit * 3)
        tip: Core.Engine.isPlaying ? i18n("Pause") : i18n("Play")
        onClicked: Core.Playback.togglePlayPause()
    }

    PlayerButton {
        iconName: "media-skip-forward"
        diameter: Math.round(Kirigami.Units.gridUnit * 2.1)
        enabled: Core.Playback.canGoNext
        tip: i18n("Next")
        onClicked: Core.Playback.nextTrack()
    }
}
