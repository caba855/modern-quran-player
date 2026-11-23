import QtQuick
import org.kde.plasma.configuration

// Plasma 6 reads this file from contents/config/; `source` paths are
// relative to contents/ui/. (Plasma adds its own "Keyboard Shortcuts" and
// "About" pages automatically.)
ConfigModel {
    ConfigCategory {
        name: i18n("Playback")
        icon: "media-playback-start"
        source: "config/PlaybackConfig.qml"
    }
    ConfigCategory {
        name: i18n("Popup")
        icon: "preferences-desktop-theme"
        source: "config/AppearanceConfig.qml"
    }
}
