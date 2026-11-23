pragma Singleton

import QtQuick
import "../../js/services/Storage.js" as Storage

// Current ayah text (Uthmani script) for the Now Playing hero.
// Cache-first: hits the LocalStorage ayah cache (30-day read TTL) before
// touching the network; a request-id guard discards stale responses.
Item {
    id: verse

    property string text: ""
    property string translation: ""
    property bool translationBusy: false
    property bool busy: false
    property int requestId: 0
    property int translationRequestId: 0
    property int currentSurah: 0
    property int currentAyah: 0

    // Quran.com translation resource 20 = Saheeh International (English).
    readonly property string translationPrefix: "tr20:"

    Connections {
        target: Session
        function onShowTranslationChanged() {
            if (Session.showTranslation && verse.currentSurah > 0) {
                verse.loadTranslation(verse.currentSurah, verse.currentAyah)
            } else if (!Session.showTranslation) {
                verse.translationRequestId += 1
                verse.translation = ""
                verse.translationBusy = false
            }
        }
    }

    function loadTranslation(surahNumber, ayahNumber) {
        translationRequestId += 1
        var rid = translationRequestId
        translation = ""
        if (!Session.showTranslation) {
            translationBusy = false
            return
        }
        var cached = Storage.getCachedAyahText(surahNumber, ayahNumber, cacheTtlMs, translationPrefix)
        if (cached && cached.length > 0) {
            translation = cached
            translationBusy = false
            return
        }
        translationBusy = true
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api.quran.com/api/v4/quran/translations/20?verse_key="
            + surahNumber + ":" + ayahNumber)
        xhr.setRequestHeader("Accept", "application/json")
        xhr.timeout = 8000
        xhr.ontimeout = function() {
            if (rid === verse.translationRequestId) {
                verse.translationBusy = false
            }
        }
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || rid !== verse.translationRequestId) {
                return
            }
            verse.translationBusy = false
            if (xhr.status !== 200) {
                return
            }
            try {
                var response = JSON.parse(xhr.responseText)
                if (response && response.translations && response.translations.length > 0) {
                    var clean = String(response.translations[0].text)
                        .replace(/<sup[^>]*>.*?<\/sup>/g, "")
                        .replace(/<[^>]+>/g, "")
                        .trim()
                    verse.translation = clean
                    Storage.saveAyahText(surahNumber, ayahNumber, clean, verse.translationPrefix)
                }
            } catch (e) {
                console.log("ModernModernQuranPlayer: failed to parse translation", e)
            }
        }
        xhr.send()
    }

    readonly property int cacheTtlMs: 30 * 24 * 60 * 60 * 1000

    function load(surahNumber, ayahNumber) {
        currentSurah = surahNumber
        currentAyah = ayahNumber
        loadTranslation(surahNumber, ayahNumber)
        requestId += 1
        var currentRequestId = requestId
        busy = true

        var cachedText = Storage.getCachedAyahText(surahNumber, ayahNumber, cacheTtlMs)
        if (cachedText && cachedText.length > 0) {
            text = cachedText
            busy = false
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api.quran.com/api/v4/quran/verses/uthmani?verse_key="
            + surahNumber + ":" + ayahNumber)
        xhr.setRequestHeader("Accept", "application/json")
        xhr.timeout = 8000
        xhr.ontimeout = function() {
            if (currentRequestId !== verse.requestId) {
                return
            }
            verse.text = ""
            verse.busy = false
        }
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return
            }
            if (currentRequestId !== verse.requestId) {
                return
            }
            verse.busy = false
            if (xhr.status !== 200) {
                verse.text = ""
                return
            }
            try {
                var response = JSON.parse(xhr.responseText)
                if (response && response.verses && response.verses.length > 0) {
                    verse.text = response.verses[0].text_uthmani
                    Storage.saveAyahText(surahNumber, ayahNumber, verse.text)
                } else {
                    verse.text = ""
                }
            } catch (e) {
                console.log("ModernQuranPlayer: failed to parse ayah text", e)
                verse.text = ""
            }
        }
        xhr.send()
    }

    function clear() {
        requestId += 1
        translationRequestId += 1
        currentSurah = 0
        currentAyah = 0
        translation = ""
        translationBusy = false
        text = ""
        busy = false
    }
}
