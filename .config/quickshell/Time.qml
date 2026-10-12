import QtQuick
import Quickshell

import "openAnim.js" as OpenAnim
import "colorConfig.js" as Colors

Item {
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: Colors.bg0

        radius: 0
        bottomLeftRadius: OpenAnim.cornerTabRadius

        Text {
            anchors.centerIn: parent
            // verticalAlignment: TextInput.AlignVCenter
            // ShorizontalAlignment: TextInput.AlignHCenter

            text: Qt.formatDateTime(clock.date, "mm:dd")

            font.pixelSize: 22
            font.family: "Iosevka Nerd Font Propo"
            font.weight: Font.Bold
            color: Colors.fg
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

}
