pragma Singleton

import QtQuick
import "../../js/services/ProviderQuranCom.js" as ProviderQuranCom

// Reciter catalog and provider health.
//
// The catalog merges the curated offline reciters with the online Quran.com
// list; when the network fails it degrades gracefully to the curated set and
// reports the failure through Status. Selection is id-based and persisted by
// Session (selectedReciterId).
Item {
    id: library

    property var reciters: []
    property bool loading: false
    // Caption shown near the reciter picker.
    property string statusMessage: ""
    // online | degraded | offline-cache
    property string networkMode: "online"
    property int providerErrorStreak: 0

    // Set on first refresh so pickers can fall back to a curated reciter even
    // before the provider answers.
    readonly property string fallbackReciterId: "curated:alafasy"

    readonly property var selectedReciter: {
        var list = reciters
        for (var i = 0; i < list.length; i += 1) {
            if (list[i] && list[i].id === Session.selectedReciterId) {
                return list[i]
            }
        }
        return list.length > 0 ? list[0] : null
    }

    function refresh() {
        if (loading) {
            return
        }
        loading = true
        var reportedError = false
        Status.setLoading(i18n("Loading reciters…"), "provider")

        ProviderQuranCom.listReciters(function(list) {
            loading = false
            reciters = list || []
            if (reportedError) {
                // The provider failed but curated reciters were returned as a
                // fallback; keep the error visible and mark degraded.
                statusMessage = i18n("Using offline reciters")
                networkMode = "offline-cache"
                return
            }
            statusMessage = i18n("Reciters loaded")
            resetProviderErrorStreak()
            ensureValidSelection()
            Status.setInfo(i18n("Reciters loaded"))
        }, function(message) {
            reportedError = true
            loading = false
            statusMessage = i18n("Using offline reciters")
            registerProviderError()
            if (providerErrorStreak >= 3) {
                selectFallbackCurated()
            }
            Status.setError(message, "provider")
        }, i18n)
    }

    function reciterById(reciterId) {
        for (var i = 0; i < reciters.length; i += 1) {
            if (reciters[i] && reciters[i].id === reciterId) {
                return reciters[i]
            }
        }
        return null
    }

    function reciterNameById(reciterId) {
        var reciter = reciterById(reciterId)
        return reciter ? String(reciter.name || "") : ""
    }

    // Keep the persisted selection valid; fall back to a curated reciter when
    // the saved id is not present in the current catalog.
    function ensureValidSelection() {
        if (reciterById(Session.selectedReciterId)) {
            return
        }
        Session.setReciterId(firstCuratedId())
    }

    function firstCuratedId() {
        for (var i = 0; i < reciters.length; i += 1) {
            if (reciters[i] && reciters[i].source === "curated") {
                return reciters[i].id
            }
        }
        return fallbackReciterId
    }

    function selectFallbackCurated() {
        var target = reciterById(fallbackReciterId)
            ? fallbackReciterId
            : firstCuratedId()
        Session.setReciterId(target)
    }

    function registerProviderError() {
        providerErrorStreak += 1
        if (providerErrorStreak >= 3) {
            networkMode = "degraded"
        }
    }

    function resetProviderErrorStreak() {
        providerErrorStreak = 0
        if (networkMode !== "offline-cache") {
            networkMode = "online"
        }
    }

    // Called by Playback when a built queue had to use fallback audio URLs.
    function noteFallbackTracks() {
        networkMode = "degraded"
    }
}
