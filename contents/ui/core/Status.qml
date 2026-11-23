pragma Singleton

import QtQuick

// The one status state machine for the whole widget.
//
// v1 had two duplicated banner implementations plus a partial third; v2 has
// exactly one Status object and one StatusBanner view. Status holds state
// only — retry/fallback buttons in the banner emit the signals below and
// Playback performs the actions (keeps the singleton graph acyclic).
Item {
    id: status

    readonly property int idle: 0
    readonly property int loading: 1
    readonly property int info: 2
    readonly property int error: 3

    signal retryRequested
    signal fallbackRequested

    property int kind: idle
    property string message: ""
    property string code: ""
    property int progress: 0
    property bool spinnerVisible: false
    property bool slowHintVisible: false

    readonly property bool hasError: kind === error
    readonly property bool busy: kind === loading
    readonly property bool bannerVisible: kind !== idle && message !== ""

    Timer {
        id: spinnerDelay
        interval: 300
        repeat: false
        onTriggered: status.spinnerVisible = true
    }

    Timer {
        id: slowHintDelay
        interval: 1500
        repeat: false
        onTriggered: status.slowHintVisible = true
    }

    function reset() {
        kind = idle
        message = ""
        code = ""
        progress = 0
        hideIndicators()
    }

    function setInfo(text) {
        kind = info
        message = text
        code = ""
        progress = 0
        hideIndicators()
    }

    function setLoading(text, newCode) {
        kind = loading
        message = text
        code = newCode || ""
        spinnerVisible = false
        slowHintVisible = false
        spinnerDelay.restart()
        slowHintDelay.restart()
    }

    function setError(text, newCode) {
        kind = error
        message = text
        code = newCode || ""
        progress = 0
        hideIndicators()
    }

    function tickProgress(value, text) {
        progress = Math.max(0, Math.min(100, value | 0))
        if (text) {
            message = text
        }
    }

    function hideIndicators() {
        spinnerDelay.stop()
        slowHintDelay.stop()
        spinnerVisible = false
        slowHintVisible = false
    }
}
