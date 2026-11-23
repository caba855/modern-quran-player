import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../core" as Core
import "../components" as Components

// The Listen page: pick reciter/surah/range, build the queue, adjust tools,
// and see what's up next.
ColumnLayout {
    id: page

    spacing: Kirigami.Units.largeSpacing

    // ---- Selection ---------------------------------------------------------
    Kirigami.AbstractCard {
        Layout.fillWidth: true

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Components.ReciterPicker {
                Layout.fillWidth: true
            }

            Components.SurahPicker {
                Layout.fillWidth: true
            }

            Components.RangeEditor {
                Layout.fillWidth: true
            }

            Components.BuildActions {
                Layout.fillWidth: true
            }
        }
    }

    // ---- Tools -------------------------------------------------------------
    Kirigami.AbstractCard {
        Layout.fillWidth: true

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Label {
                    text: i18n("Volume")
                    color: Core.Theme.secondaryTextColor
                }

                Slider {
                    id: volumeSlider
                    Layout.fillWidth: true
                    from: 0.0
                    to: 1.0
                    stepSize: 0.01
                    value: Core.Session.volume

                    onMoved: Core.Session.setVolume(volumeSlider.value)
                }

                Label {
                    text: Math.round(Core.Session.volume * 100) + "%"
                    color: Core.Theme.secondaryTextColor
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                }
            }

            Components.SleepTimerPicker {
                Layout.fillWidth: true
            }

            Components.RepeatToolsSection {
                Layout.fillWidth: true
            }
        }
    }

    // ---- Queue -------------------------------------------------------------
    Kirigami.AbstractCard {
        Layout.fillWidth: true

        contentItem: Components.QueueList {
            Layout.fillWidth: true
        }
    }
}
