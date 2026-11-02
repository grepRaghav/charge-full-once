import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.notification

PlasmoidItem {
    id: root

    property bool active: false
    property bool supported: true
    property int level: 0
    property string endLimit: "-"
    property string startLimit: "-"
    property string pending: ""
    readonly property string helper: "/usr/local/bin/charge-full-once"

    toolTipMainText: !supported ? "Charge limits not supported"
                   : active ? "Charging to 100% (one time)"
                   : "Charge to 100% once"
    toolTipSubText: !supported ? "No battery with charge thresholds found"
                  : (active ? "Click to cancel and restore your normal limits.\n"
                            : "Click to lift the charge limit for this charge.\n")
                    + "Battery " + level + "% | current limits: start " + startLimit + ", stop " + endLimit

    Notification {
        id: notif
        componentName: "plasma_workspace"
        eventId: "notification"
    }

    function notify(title, body, icon) {
        notif.title = title
        notif.text = body
        notif.iconName = icon
        notif.sendEvent()
    }

    function refresh() { exec.connectSource(helper + " status") }

    function toggle() {
        if (!supported) {
            notify("Charge limits not supported", "No battery with charge thresholds was found.", "dialog-error")
            return
        }
        pending = active ? "cancel" : "start"
        exec.connectSource("sudo -n " + helper + " " + pending)
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source)

            if (source.endsWith(" status")) {
                var p = (data["stdout"] || "").trim().split(" ")
                root.supported = p[0] !== "unsupported"
                root.active = p[0] === "active"
                root.level = parseInt(p[1]) || 0
                root.endLimit = p[2] || "-"
                root.startLimit = p[3] || "-"
                return
            }

            var ok = data["exit code"] === 0
            var err = (data["stderr"] || "").trim()
            if (ok && root.pending === "start") {
                root.notify("Charging to 100%", "Limits lifted for this charge. They will be restored automatically when charging stops.", "battery-100-charging")
            } else if (ok && root.pending === "cancel") {
                root.notify("Normal charge limits restored", "Back to your usual start/stop limits.", "battery-080")
            } else {
                root.notify("Charge toggle failed", err !== "" ? err : "Command failed (is the sudoers rule installed?)", "dialog-error")
            }
            root.pending = ""
            root.refresh()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Shown on the desktop (and in a popup if placed in a panel's hidden area)
    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 9
        Layout.minimumHeight: Kirigami.Units.gridUnit * 9
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
        Layout.preferredHeight: Kirigami.Units.gridUnit * 10
        spacing: Kirigami.Units.smallSpacing

        Item { Layout.fillHeight: true }

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            source: root.active ? "battery-100-charging" : "battery-080"
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.active ? "Charging to 100%" : "Charge to 100% once"
            font.bold: true
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Battery " + root.level + "%  |  limits " + root.startLimit + " - " + root.endLimit
            opacity: 0.7
        }

        PlasmaComponents.Button {
            Layout.alignment: Qt.AlignHCenter
            text: root.active ? "Cancel and restore limits" : "Charge to 100% once"
            onClicked: root.toggle()
        }

        Item { Layout.fillHeight: true }
    }

    // Shown when placed in a panel: a single click toggles
    compactRepresentation: MouseArea {
        hoverEnabled: true
        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        onClicked: root.toggle()

        Kirigami.Icon {
            id: icon
            anchors.fill: parent
            source: root.active ? "battery-100-charging" : "battery-080"
            opacity: root.supported ? 1.0 : 0.4
        }

        Text {
            anchors.centerIn: parent
            visible: !icon.valid
            text: root.active ? "100%" : "80%"
            color: Kirigami.Theme.textColor
            font.bold: true
            font.pixelSize: Math.max(8, parent.height * 0.4)
        }

        Rectangle {
            visible: root.active
            width: parent.width * 0.34
            height: width
            radius: width / 2
            color: Kirigami.Theme.positiveTextColor
            border.color: Kirigami.Theme.backgroundColor
            border.width: 1
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }
}
