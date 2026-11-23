import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../components" as Components

// The Library page: quick start, presets and bookmarks.
ColumnLayout {
    id: page

    spacing: Kirigami.Units.largeSpacing

    // Responsive hint derived from the page's own width.
    readonly property bool narrow: width > 0 && width < Kirigami.Units.gridUnit * 26

    Kirigami.AbstractCard {
        Layout.fillWidth: true

        contentItem: Components.QuickStartGrid {
            Layout.fillWidth: true
            columns: page.narrow ? 2 : 3
        }
    }

    Kirigami.AbstractCard {
        Layout.fillWidth: true

        contentItem: Components.KhatmCard {
            Layout.fillWidth: true
        }
    }

    Kirigami.AbstractCard {
        Layout.fillWidth: true

        contentItem: Components.CollectionList {
            Layout.fillWidth: true
            kind: "presets"
        }
    }

    Kirigami.AbstractCard {
        Layout.fillWidth: true

        contentItem: Components.CollectionList {
            Layout.fillWidth: true
            kind: "bookmarks"
        }
    }
}
