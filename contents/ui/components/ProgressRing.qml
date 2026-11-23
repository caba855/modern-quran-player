import QtQuick
import org.kde.kirigami as Kirigami

import "../core" as Core

// A thin circular progress ring, theme-colored. Reused by the panel play
// button (track progress) and the khatm card (0-114 progress).
Item {
    id: ring

    // 0..1
    property real progress: 0
    property real size: Kirigami.Units.iconSizes.medium
    property color trackColor: Core.Theme.surfaceMuted
    property color progressColor: Core.Theme.accentColor
    property real ringWidth: Math.max(2, Math.round(size * 0.08))

    implicitWidth: size
    implicitHeight: size

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        property real ringProgress: ring.progress
        property color ringTrack: ring.trackColor
        property color ringFill: ring.progressColor
        property real strokeWidth: ring.ringWidth

        onRingProgressChanged: requestPaint()
        onRingTrackChanged: requestPaint()
        onRingFillChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2
            var cy = height / 2
            var radius = Math.max(1, Math.min(cx, cy) - strokeWidth / 2)

            // Track.
            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, Math.PI * 2)
            ctx.lineWidth = strokeWidth
            ctx.strokeStyle = ringTrack
            ctx.stroke()

            // Progress arc from 12 o'clock, clockwise.
            var clamped = Math.max(0, Math.min(1, ringProgress))
            if (clamped > 0) {
                var start = -Math.PI / 2
                var end = start + clamped * Math.PI * 2
                ctx.beginPath()
                ctx.arc(cx, cy, radius, start, end)
                ctx.lineWidth = strokeWidth
                ctx.lineCap = "round"
                ctx.strokeStyle = ringFill
                ctx.stroke()
            }
        }
    }

    Behavior on progress {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
}
