import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../js/services/Labels.js" as Labels
import "../../js/data/SurahMeta.js" as SurahMeta
import "../core" as Core

// The Now Playing hero, dressed as an illuminated manuscript page:
// emerald wash, faint khatam (eight-point-star) lattice, double gold frame,
// ornamental dividers, a verse-end medallion and an emerald play disc.
Kirigami.AbstractCard {
    id: hero

    padding: Kirigami.Units.largeSpacing + 4

    // ---- Continue-listening (explicit session restore) --------------------
    readonly property var lastSession: Core.Session.lastSessionSnapshot
    readonly property var continueTrack: {
        var session = hero.lastSession
        if (!session || !session.queue || session.queue.length === 0) {
            return null
        }
        var index = Math.max(0, Math.min(session.currentIndex || 0, session.queue.length - 1))
        return session.queue[index]
    }
    readonly property bool showContinue: Core.QueueStore.empty && hero.continueTrack !== null

    readonly property var track: Core.Playback.currentTrack
    readonly property string surahArabic: {
        if (!hero.track) {
            return ""
        }
        var meta = SurahMeta.byNumber(hero.track.surahNumber)
        return meta && meta.nameAr ? "سورة " + meta.nameAr : ""
    }

    function arabicDigits(n) {
        var map = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(n).replace(/[0-9]/g, function(d) { return map[d] })
    }

    contentItem: ColumnLayout {
        id: heroLayout
        spacing: Kirigami.Units.smallSpacing

        // ---- Header ---------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Image {
                source: "../images/quran-icon.png"
                Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.smallMedium * 1.437)
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Label {
                Layout.fillWidth: true
                text: i18n("Modern Quran Player")
                font.bold: true
                color: Core.Theme.goldColor
                elide: Text.ElideRight
            }

            PlayingIndicator {
                visible: Core.Playback.isPlaying
                playing: Core.Playback.isPlaying
                barColor: Core.Theme.emeraldColor
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }

            Label {
                visible: text !== ""
                text: Core.Playback.queuePositionLabel
                font: Core.Theme.smallFont
                color: Core.Theme.secondaryTextColor
                leftPadding: Kirigami.Units.smallSpacing
                rightPadding: Kirigami.Units.smallSpacing
                topPadding: 2
                bottomPadding: 2

                background: Rectangle {
                    radius: height / 2
                    color: "transparent"
                    border.color: Core.Theme.goldSoft
                    border.width: 1
                }
            }

            ToolButton {
                icon.name: "window-pin"
                display: AbstractButton.IconOnly
                checkable: true
                checked: Core.Session.pinned
                onToggled: Core.Session.setPinned(checked)
                Accessible.name: i18n("Keep popup open")
                ToolTip.text: checked ? i18n("Unpin (close when focus is lost)") : i18n("Pin (keep popup open)")
                ToolTip.visible: hovered
                ToolTip.delay: 500
            }

            ToolButton {
                text: "EN"
                font.bold: true
                checkable: true
                checked: Core.Session.showTranslation
                onToggled: Core.Session.setShowTranslation(checked)
                Accessible.name: i18n("English translation")
                ToolTip.text: i18n("English translation")
                ToolTip.visible: hovered
                ToolTip.delay: 500
            }

            ToolButton {
                icon.name: Core.Session.showControls ? "go-previous" : "go-next"
                display: AbstractButton.IconOnly
                onClicked: Core.Session.setShowControls(!Core.Session.showControls)
                Accessible.name: Core.Session.showControls ? i18n("Hide side panel") : i18n("Show side panel")
                ToolTip.text: Core.Session.showControls ? i18n("Hide side panel") : i18n("Show side panel")
                ToolTip.visible: hovered
                ToolTip.delay: 500
            }
        }

        // ---- Continue listening ----------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            visible: hero.showContinue

            Kirigami.Icon {
                source: "view-refresh"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                color: Core.Theme.secondaryTextColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    text: i18n("Continue listening")
                    font: Core.Theme.smallFont
                    color: Core.Theme.secondaryTextColor
                }

                Label {
                    Layout.fillWidth: true
                    text: hero.continueTrack
                        ? Labels.trackLabel(hero.continueTrack, Core.Session.uiLocale)
                        : ""
                    elide: Text.ElideRight
                }
            }

            Button {
                text: i18n("Resume")
                icon.name: "media-playback-start"
                onClicked: Core.Playback.restoreSession(hero.lastSession)
            }

            ToolButton {
                icon.name: "window-close"
                display: AbstractButton.IconOnly
                onClicked: Core.Session.clearLastSession()
                Accessible.name: i18n("Dismiss")
                ToolTip.text: i18n("Dismiss")
                ToolTip.delay: 500
            }
        }

        // ---- Title block (centered) ------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            visible: hero.track !== null

            Label {
                Layout.fillWidth: true
                visible: hero.surahArabic !== ""
                text: hero.surahArabic
                font.family: Core.Theme.arabicFontFamily
                font.pointSize: Core.Theme.arabicPointSize * 0.95
                color: Core.Theme.goldColor
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                Layout.fillWidth: true
                text: Core.Playback.currentTrackLabel
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                text: Core.Library.selectedReciter ? Core.Library.selectedReciter.name : ""
                visible: text !== ""
                font: Core.Theme.smallFont
                color: Core.Theme.secondaryTextColor
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        OrnamentDivider {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
        }

        // ---- Verse panel ---------------------------------------------------------
        // Fixed height so the popup never jumps; long verses scroll inside.
        Item {
            id: verseArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Math.round(4 * Kirigami.Units.gridUnit)
            Layout.preferredHeight: Math.round((Core.Session.showTranslation ? 12 : 8) * Kirigami.Units.gridUnit)

            Flickable {
                id: verseFlick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: verseColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: verseColumn
                    width: verseFlick.width
                    y: Math.max(0, (verseFlick.height - implicitHeight) / 2)
                    spacing: Kirigami.Units.smallSpacing

                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.rightMargin: Kirigami.Units.smallSpacing
                        visible: Core.Verse.text !== ""
                        text: Core.Verse.text
                        font.family: Core.Theme.arabicFontFamily
                        font.pointSize: Core.Theme.arabicPointSize * 1.1
                        lineHeight: 1.35
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: Core.Theme.textColor
                    }

                    AyahMedallion {
                        Layout.alignment: Qt.AlignHCenter
                        visible: Core.Verse.text !== "" && hero.track !== null && !hero.track.isFullSurah
                        label: hero.track ? hero.arabicDigits(hero.track.ayahNumber) : ""
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.rightMargin: Kirigami.Units.smallSpacing
                        visible: Core.Session.showTranslation && Core.Verse.translation !== ""
                        text: Core.Verse.translation
                        font.italic: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: Core.Theme.secondaryTextColor
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                width: parent.width
                visible: Core.Verse.text === "" && !Core.Verse.busy
                text: hero.track !== null && hero.track.isFullSurah
                    ? i18n("Playing full surah")
                    : i18n("Press play to start listening")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Core.Theme.secondaryTextColor
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: visible
                visible: Core.Verse.busy && Core.Verse.text === "" && hero.track !== null
                width: Kirigami.Units.iconSizes.smallMedium
                height: Kirigami.Units.iconSizes.smallMedium
            }
        }

        OrnamentDivider {
            Layout.fillWidth: true
        }

        // ---- Seek + transport -----------------------------------------------
        SeekBar {
            Layout.fillWidth: true
        }

        TransportBar {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }
    }

    background: Rectangle {
        radius: Kirigami.Units.largeSpacing
        color: Qt.tint(Kirigami.Theme.backgroundColor,
                       Qt.rgba(Core.Theme.emeraldColor.r, Core.Theme.emeraldColor.g, Core.Theme.emeraldColor.b, 0.12))
        border.color: Core.Theme.goldColor
        border.width: 1

        // Khatam lattice.
        Item {
            anchors.fill: parent
            anchors.margins: 3
            clip: true

            Image {
                anchors.fill: parent
                source: "../images/pattern.svg"
                fillMode: Image.Tile
                opacity: 0.07
            }
        }

        // Inner hairline frame (double border).
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: parent.radius - 3
            color: "transparent"
            border.color: Core.Theme.goldSoft
            border.width: 1
        }

        // Corner stars.
        Repeater {
            model: 4

            Rectangle {
                required property int index
                width: 7
                height: 7
                rotation: 45
                color: Core.Theme.goldColor
                x: (index % 2 === 0) ? 1 : parent.width - width - 1
                y: (index < 2) ? 1 : parent.height - height - 1
            }
        }
    }
}
