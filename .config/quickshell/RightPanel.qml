import QtQuick
import Quickshell
import Quickshell.Io
// import QtQuick.Layout

import "colorConfig.js" as Colors

Rectangle {
    id: root

    anchors.fill: parent
    color: Colors.bg0

    property string ramUsage: "4GiB"

    Column {
        Text {
            text: cpuProces.output
        }

        Text {
            text: ramProces.output
        }
    }

    RunCommandOnRepeat {
        id: cpuProces
        interval: 2500
        cmd: "top -bn1 | grep '%Cpu' | awk '{print int(100 - $8)}'"
    }

    RunCommandOnRepeat {
        id: ramProces
        interval: 2500
        cmd: "top -bn1 | grep '%Cpu' | awk '{print int(100 - $8)}'"
    }
}