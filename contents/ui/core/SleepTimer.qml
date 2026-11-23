pragma Singleton

import QtQuick

// Sleep timer: counts down once per minute while active and pauses playback
// at zero. Remaining time is persisted by Session (kcfg), so a countdown in
// progress survives a Plasma restart.
Item {
    id: sleepTimer

    readonly property int remainingMinutes: Session.sleepRemainingMinutes
    readonly property bool active: Session.sleepRemainingMinutes > 0

    Timer {
        id: tickTimer
        interval: 60000
        repeat: true
        running: Session.sleepRemainingMinutes > 0
        onTriggered: {
            var remaining = Session.sleepRemainingMinutes - 1
            Session.setSleepRemaining(remaining)
            if (remaining <= 0) {
                if (Playback.isPlaying) {
                    Playback.requestPause()
                }
                Status.setInfo(i18n("Sleep timer finished"))
            }
        }
    }

    function set(minutes) {
        var value = Math.max(0, minutes | 0)
        Session.setSleepRemaining(value)
        if (value > 0) {
            Status.setInfo(i18n("Sleep timer set: %1 min", value))
        } else {
            Status.setInfo(i18n("Sleep timer off"))
        }
    }
}
