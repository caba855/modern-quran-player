pragma Singleton

import QtQuick
import "../../js/services/Storage.js" as Storage
import "../../js/data/SurahMeta.js" as SurahMeta

// Khatm (listening through the whole Quran) progress tracker.
//
// A surah counts as listened when a queue that covered its entire scope
// finishes — Playback emits queueCompleted(surah, wasFullScope) and this
// object records it. Progress persists across restarts (Storage table).
Item {
    id: khatm

    // { [surahNumber]: { completedAt, listenCount } }
    property var completedMap: ({})

    readonly property int total: 114
    readonly property int completedCount: Object.keys(completedMap).length
    readonly property real progressRatio: total > 0 ? completedCount / total : 0

    signal changed

    Connections {
        target: Playback
        function onQueueCompleted(surahNumber, wasFullScope) {
            if (!wasFullScope || surahNumber <= 0) {
                return
            }
            Storage.markSurahCompleted(surahNumber)
            khatm.reload()
            Status.setInfo(i18n("Surah %1 marked as listened — %2 of %3",
                SurahMeta.label(surahNumber, Session.uiLocale),
                khatm.completedCount, khatm.total))
        }
    }

    function reload() {
        completedMap = Storage.listKhatm()
        changed()
    }

    function isCompleted(surahNumber) {
        return completedMap[surahNumber] !== undefined
    }

    function resetSurah(surahNumber) {
        Storage.removeKhatm(surahNumber)
        reload()
    }

    function resetAll() {
        Storage.clearKhatm()
        reload()
    }
}
