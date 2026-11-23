.pragma library

.import "../data/SurahMeta.js" as SurahMeta

// Pure label-formatting helpers. No Qt/QML dependencies; unit-tested via node.

function surahName(surahNumber, locale) {
    var surah = SurahMeta.byNumber(surahNumber);
    if (!surah) {
        return i18nSafe("Surah") + " " + surahNumber;
    }
    if (locale && String(locale).toLowerCase().indexOf("ar") === 0) {
        return surah.nameAr;
    }
    return surah.nameEn;
}

function surahLabel(surahNumber, locale) {
    return surahNumber + ". " + surahName(surahNumber, locale);
}

function trackLabel(track, locale) {
    if (!track) {
        return "";
    }
    if (track.isFullSurah) {
        return surahLabel(track.surahNumber, locale);
    }
    return surahName(track.surahNumber, locale) + " " + track.surahNumber + ":" + track.ayahNumber;
}

function trackSubtitle(track) {
    if (!track) {
        return "";
    }
    return String(track.reciterName || "");
}

function queuePositionLabel(index, count) {
    if (index < 0 || count <= 0) {
        return "";
    }
    return (index + 1) + " / " + count;
}

function reciterNameById(reciters, reciterId) {
    var list = reciters || [];
    for (var i = 0; i < list.length; i += 1) {
        if (list[i] && list[i].id === reciterId) {
            return String(list[i].name || reciterId);
        }
    }
    return "";
}

// Node/test fallback: i18n() exists only inside plasmoids.
function i18nSafe(text) {
    if (typeof i18n === "function") {
        return i18n(text);
    }
    return text;
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        surahName: surahName,
        surahLabel: surahLabel,
        trackLabel: trackLabel,
        trackSubtitle: trackSubtitle,
        queuePositionLabel: queuePositionLabel,
        reciterNameById: reciterNameById
    };
}
