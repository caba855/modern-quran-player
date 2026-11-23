pragma Singleton

import QtQuick
import "../../js/services/Storage.js" as Storage
import "../../js/services/PlaybackController.js" as PlaybackController
import "../../js/services/Labels.js" as Labels

// Bookmarks and presets facade over Storage.
//
// A bookmark is a saved position (surah + ayah + reciter). A preset is a
// saved listening configuration (reciter, surah/range, mode, speed, repeats,
// volume). Both live in SQLite; this object exposes them and the actions the
// Library page needs.
Item {
    id: collection

    property var bookmarks: []
    property var presets: []

    function reload() {
        bookmarks = Storage.listBookmarks()
        presets = Storage.listPresets()
    }

    // ---- Bookmarks ---------------------------------------------------------
    function addBookmark() {
        var track = Playback.currentTrack
        if (!track) {
            Status.setError(i18n("Nothing to bookmark"), "validation")
            return
        }
        Storage.saveBookmark({
            label: Labels.trackLabel(track, Session.uiLocale),
            surahNumber: track.surahNumber,
            ayahNumber: track.isFullSurah ? 1 : track.ayahNumber,
            reciterId: Session.selectedReciterId
        })
        reload()
        Status.setInfo(i18n("Bookmark saved"))
    }

    function removeBookmark(id) {
        Storage.removeBookmark(id)
        reload()
    }

    function jumpToBookmark(bookmark) {
        if (!bookmark) {
            return
        }
        if (bookmark.reciterId) {
            Session.setReciterId(bookmark.reciterId)
        }
        Session.setSurah(bookmark.surahNumber)
        Session.setRange(bookmark.ayahNumber, bookmark.ayahNumber)
        Session.setPlaybackMode(PlaybackController.PLAYBACK_RANGE)
        Playback.buildQueue(true)
    }

    // ---- Presets -----------------------------------------------------------
    function savePreset(label) {
        Storage.savePreset({
            label: label && label.length > 0 ? label : i18n("Custom preset"),
            reciterId: Session.selectedReciterId,
            surahNumber: Session.selectedSurah,
            startAyah: Session.startAyah,
            endAyah: Session.endAyah,
            playbackMode: Session.playbackMode,
            repeatMode: Session.repeatMode,
            ayahRepeatTarget: Session.ayahRepeatTarget,
            volume: Session.volume
        })
        reload()
        Status.setInfo(i18n("Preset saved"))
    }

    function removePreset(id) {
        Storage.removePreset(id)
        reload()
    }

    function applyPreset(preset) {
        if (!preset) {
            return
        }
        if (preset.reciterId) {
            Session.setReciterId(preset.reciterId)
        }
        Session.setSurah(preset.surahNumber || 1)
        Session.setRange(preset.startAyah || 1, preset.endAyah || (preset.startAyah || 1))
        var mode = preset.playbackMode
        if (mode !== PlaybackController.PLAYBACK_RANGE && mode !== PlaybackController.PLAYBACK_FULL_SURAH) {
            mode = PlaybackController.PLAYBACK_RANGE
        }
        Session.setPlaybackMode(mode)
        Session.setRepeatMode(preset.repeatMode !== undefined ? preset.repeatMode : PlaybackController.REPEAT_NONE)
        Session.setAyahRepeatTarget(preset.ayahRepeatTarget !== undefined ? preset.ayahRepeatTarget : 1)
        Session.setVolume(preset.volume !== undefined ? preset.volume : 0.85)
        Playback.buildQueue(false)
        Status.setInfo(i18n("Preset applied"))
    }
}
