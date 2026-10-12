import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootScope

    required property string cmd
    required property int interval
    property string output: "0%"

    Process {
        id: process
        command: ["sh", "-c", rootScope.cmd]

        stdout: SplitParser {
            onRead: data => {
                rootScope.output = data.trim() + "%"
            }
        }
    }

    Timer {
        interval: rootScope.interval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!process.running) {
                process.running = true
            }
        }
    }
}