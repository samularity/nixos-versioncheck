import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // replaced with the store path at build time
    readonly property string checker: "@checker@"

    property var st: null
    property string lastError: ""
    property bool checking: false

    readonly property bool lockStale: st !== null && st.lockStale
    readonly property bool upgrade: st !== null && st.upgradeAvailable
    readonly property bool attention: lockStale || upgrade || lastError !== ""

    function ageText(days) {
        if (days === null || days === undefined) return i18n("unknown");
        if (days === 0) return i18n("today");
        if (days === 1) return i18n("yesterday");
        return i18n("%1 days ago", days);
    }

    function dateText(epoch) {
        return epoch ? Qt.formatDate(new Date(epoch * 1000), Qt.ISODate) : "–";
    }

    readonly property string lockLine: st && st.lock
        ? i18n("%1 (%2) locked %3", st.input, st.lock.ref || "?", ageText(st.ageDays))
        : i18n("No %1 input found in flake.lock", st ? st.input : "nixpkgs")

    readonly property string releaseLine: {
        if (!st || !st.latest) return i18n("Release check pending");
        if (st.upgradeAvailable) return i18n("NixOS %1 is out – you are on %2", st.latest, st.current);
        if (st.current) return i18n("%1 is the latest release", st.current);
        return i18n("Tracking %1, latest release: %2", st.lock ? st.lock.ref : "?", st.latest);
    }

    Plasmoid.icon: "nix-snowflake"
    Plasmoid.status: attention ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.ActiveStatus
    toolTipMainText: upgrade ? i18n("NixOS %1 available", st.latest)
                   : lockStale ? i18n("flake.lock is %1 days old", st.ageDays)
                   : i18n("NixOS is up to date")
    toolTipSubText: lastError !== "" ? lastError : lockLine + "\n" + releaseLine

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            if (source.endsWith(" status")) {
                if (data["exit code"] !== 0) {
                    root.lastError = i18n("nixos-update-check failed: %1", data.stderr);
                    return;
                }
                try {
                    root.st = JSON.parse(data.stdout);
                    root.lastError = "";
                } catch (e) {
                    root.lastError = i18n("Could not parse checker output");
                }
            } else {
                root.checking = false;
                root.refresh();
            }
        }
    }

    function refresh() { exec.connectSource(checker + " status"); }
    function checkRelease() {
        checking = true;
        exec.connectSource(checker + " release --force");
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    compactRepresentation: MouseArea {
        onClicked: root.expanded = !root.expanded
        Kirigami.Icon {
            anchors.fill: parent
            source: "nix-snowflake"
            active: parent.containsMouse
        }
        Rectangle {
            visible: root.attention
            width: Math.round(parent.width * 0.45)
            height: width
            radius: width / 2
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: root.upgrade || root.lastError !== "" ? Kirigami.Theme.negativeTextColor
                                                         : Kirigami.Theme.neutralTextColor
            border.color: Kirigami.Theme.backgroundColor
            border.width: 1
        }
        hoverEnabled: true
    }

    fullRepresentation: PlasmaExtras.Representation {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 13
        collapseMarginsHint: true

        header: PlasmaExtras.PlasmoidHeading {
            RowLayout {
                anchors.fill: parent
                Kirigami.Heading {
                    level: 2
                    text: i18n("NixOS updates")
                    Layout.fillWidth: true
                }
                PlasmaComponents3.ToolButton {
                    icon.name: "view-refresh"
                    enabled: !root.checking
                    onClicked: root.checkRelease()
                    PlasmaComponents3.ToolTip { text: i18n("Check for a new release now") }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            component StatusRow: RowLayout {
                id: row
                property string iconName
                property string title
                property string detail
                spacing: Kirigami.Units.largeSpacing
                Layout.fillWidth: true
                Kirigami.Icon {
                    source: row.iconName
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    Layout.alignment: Qt.AlignTop
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    PlasmaComponents3.Label {
                        text: row.title
                        font.bold: true
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    PlasmaComponents3.Label {
                        text: row.detail
                        opacity: 0.7
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            StatusRow {
                iconName: root.lockStale ? "update-medium" : "update-none"
                title: root.lockStale ? i18n("flake.lock is older than %1 days", root.st.maxAgeDays)
                                      : i18n("flake.lock is fresh")
                detail: root.lockLine + (root.st && root.st.lock ? " · " + root.dateText(root.st.lock.lastModified) : "")
                        + (root.st && root.st.rebuildPending ? "\n" + i18n("Lock changed – rebuild pending (running %1)", root.st.running) : "")
            }

            StatusRow {
                iconName: root.upgrade ? "update-high" : "update-none"
                title: root.releaseLine
                detail: root.checking ? i18n("Checking…")
                      : root.st && root.st.releaseError ? i18n("Last check failed: %1", root.st.releaseError)
                      : root.st && root.st.releaseCheckedAt ? i18n("Checked %1", new Date(root.st.releaseCheckedAt * 1000).toLocaleString(Qt.locale(), Locale.ShortFormat))
                      : ""
            }

            PlasmaComponents3.Label {
                visible: root.lastError !== ""
                text: root.lastError
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            PlasmaComponents3.Label {
                visible: root.attention && root.st !== null
                text: root.upgrade
                      ? i18n("Edit %1/flake.nix: nixos-%2 → nixos-%3", root.st.flake, root.st.current, root.st.latest)
                      : i18n("cd %1 && nix flake update && sudo nixos-rebuild switch", root.st ? root.st.flake : "")
                font.family: "monospace"
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
    }
}
