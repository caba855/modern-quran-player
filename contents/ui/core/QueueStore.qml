pragma Singleton

import QtQuick

// Queue data only: the list of tracks and the current position.
// Orchestration (building, transport, repeat policy) lives in Playback;
// keeping them apart is what prevents a new god object.
Item {
    id: store

    property int currentIndex: -1

    // Stamped by Playback when a queue is built; the khatm tracker uses it
    // to decide whether a finished queue covered the whole surah.
    property int queueSurahNumber: 0
    property bool queueIsFullScope: false

    readonly property int count: trackModel.count
    readonly property bool empty: trackModel.count === 0
    readonly property var currentTrack: currentIndex >= 0 && currentIndex < trackModel.count
        ? trackModel.get(currentIndex)
        : null
    readonly property string currentTrackId: currentTrack ? String(currentTrack.trackId || "") : ""

    signal tracksChanged

    // Exposed for views that render the queue (QueueList).
    readonly property alias queueModel: trackModel

    ListModel {
        id: trackModel
    }

    // Track objects must carry a consistent role set for ListModel.
    function normalizeTrack(track) {
        return {
            trackId: String(track.trackId || ""),
            surahNumber: track.surahNumber | 0,
            ayahNumber: track.ayahNumber | 0,
            reciterId: String(track.reciterId || ""),
            reciterName: String(track.reciterName || ""),
            url: String(track.url || ""),
            isFullSurah: track.isFullSurah === true,
            source: String(track.source || "")
        }
    }

    // Sets currentIndex to the first track when the list is non-empty.
    function loadQueue(list) {
        trackModel.clear()
        var items = list || []
        for (var i = 0; i < items.length; i += 1) {
            trackModel.append(normalizeTrack(items[i]))
        }
        currentIndex = items.length > 0 ? 0 : -1
        tracksChanged()
    }

    function trackAt(index) {
        if (index < 0 || index >= trackModel.count) {
            return null
        }
        return trackModel.get(index)
    }

    // Removes a track and keeps currentIndex pointing at the same track when
    // possible. Removal of the current track is resolved by Playback.
    function removeTrack(index) {
        if (index < 0 || index >= trackModel.count) {
            return
        }
        trackModel.remove(index)
        if (currentIndex > index) {
            currentIndex -= 1
        } else if (currentIndex >= trackModel.count) {
            currentIndex = trackModel.count - 1
        }
        tracksChanged()
    }

    // Returns the removed index, or -1 when nothing matched.
    function removeTrackById(trackId) {
        var index = findIndexByTrackId(trackId)
        if (index < 0) {
            return -1
        }
        removeTrack(index)
        return index
    }

    function findIndexByTrackId(trackId) {
        for (var i = 0; i < trackModel.count; i += 1) {
            if (String(trackModel.get(i).trackId) === String(trackId)) {
                return i
            }
        }
        return -1
    }

    function setCurrentIndex(index) {
        if (index < 0 || index >= trackModel.count) {
            return
        }
        currentIndex = index
    }

    function setCurrentByTrackId(trackId) {
        var index = findIndexByTrackId(trackId)
        if (index >= 0) {
            currentIndex = index
        }
    }

    function clear() {
        trackModel.clear()
        currentIndex = -1
        queueSurahNumber = 0
        queueIsFullScope = false
        tracksChanged()
    }

    function snapshot() {
        var list = []
        for (var i = 0; i < trackModel.count; i += 1) {
            var item = trackModel.get(i)
            list.push({
                trackId: item.trackId,
                surahNumber: item.surahNumber,
                ayahNumber: item.ayahNumber,
                reciterId: item.reciterId,
                reciterName: item.reciterName,
                url: item.url,
                isFullSurah: item.isFullSurah,
                source: item.source
            })
        }
        return list
    }

    function restoreFrom(list, index) {
        loadQueue(list)
        if (index >= 0 && index < trackModel.count) {
            currentIndex = index
        }
    }
}
