pragma Singleton

import QtQuick
import org.kde.kirigami as Kirigami

// Design tokens for the whole widget.
//
// Rules:
// - Every color derives from the active Kirigami/Plasma theme roles.
//   No hex literals anywhere in contents/ui (enforced by smoke-check).
// - Typography derives from the theme fonts; sizes are multipliers of the
//   default point size, so system font scaling works without a uiScale knob.
QtObject {
    id: theme

    // ---- Colors -----------------------------------------------------------

    readonly property color textColor: Kirigami.Theme.textColor
    readonly property color secondaryTextColor: withAlpha(Kirigami.Theme.textColor, 0.65)
    readonly property color disabledTextColor: Kirigami.Theme.disabledTextColor
    readonly property color accentColor: Kirigami.Theme.highlightColor
    readonly property color positiveColor: Kirigami.Theme.positiveTextColor
    readonly property color neutralColor: Kirigami.Theme.neutralTextColor
    readonly property color negativeColor: Kirigami.Theme.negativeTextColor
    readonly property color surfaceColor: Kirigami.Theme.backgroundColor
    readonly property color focusRingColor: Kirigami.Theme.focusColor

    // Islamic palette: emerald + antique gold (works on light and dark).
    readonly property color emeraldColor: "#1e8f63"
    readonly property color emeraldDeep: "#146846"
    readonly property color goldColor: "#c9a54e"
    readonly property color goldSoft: withAlpha("#c9a54e", 0.35)
    readonly property color goldClear: withAlpha("#c9a54e", 0.0)
    readonly property color goldFaint: withAlpha("#c9a54e", 0.18)

    // Derived surfaces (kept extremely subtle; the Breeze palette does the work).
    readonly property color surfaceMuted: withAlpha(Kirigami.Theme.textColor, 0.05)
    readonly property color borderColor: withAlpha(Kirigami.Theme.textColor, 0.15)
    readonly property color heroWash: withAlpha(Kirigami.Theme.highlightColor, 0.07)
    readonly property color heroWashStrong: withAlpha(Kirigami.Theme.highlightColor, 0.12)

    // ---- Typography -------------------------------------------------------

    readonly property font baseFont: Kirigami.Theme.defaultFont
    readonly property font smallFont: Kirigami.Theme.smallFont

    // Point size of the system default font, with a sane floor.
    readonly property real basePointSize: Kirigami.Theme.defaultFont.pointSize > 0
        ? Kirigami.Theme.defaultFont.pointSize
        : 10

    readonly property real captionPointSize: Math.max(7.5, basePointSize * 0.8)
    readonly property real bodyPointSize: basePointSize
    readonly property real headingPointSize: basePointSize * 1.2
    readonly property real heroPointSize: basePointSize * 1.45
    readonly property real arabicPointSize: Math.max(16, basePointSize * 2.1)

    // Preferred families for Uthmani text; first installed one wins.
    // Deliberately NOT bundled: Arabic script rendering is best left to a
    // font the user already chose system-wide.
    readonly property string arabicFontFamily: [
        "Amiri Quran",
        "Scheherazade New",
        "KFGQPC Uthmanic Script HAFS",
        "Amiri",
        "Noto Naskh Arabic",
        "serif"
    ].join(",")

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }
}
