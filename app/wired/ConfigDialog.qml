/*
 * Copyright (C) 2016 The Qt Company Ltd.
 * Copyright (C) 2019 Konsulko Group
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import AGL.Demo.Controls 1.0


Dialog {
    id: root
    property string serviceName: undefined
    property alias xpos: root.x
    property alias ypos: root.y
    property alias maxpwidth: root.width
    property alias maxpheight: root.height
    property alias staticAddress: m_staticAddress.text
    property alias staticNetmask: m_staticNetmask.text
    property alias staticGateway: m_staticGateway.text
    property alias dnslist: m_dnslist.text

    property bool isIPv4: true
    property bool isStatic: false
    property bool isManualDNS: false

    signal finished(string svc, string ipv, string ipa, string nm, string gw, string dns)

    visible: false
    z: 1
    focus: true
    modal: true
    footer: DialogButtonBox {
        Button { text: "APPLY"
                 DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
        Button { text: "CLOSE"
                 DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
        Button { text: "RESET"
                 DialogButtonBox.buttonRole: DialogButtonBox.ResetRole
        }
        background: Rectangle {
            border.color : '#00ADDC'
            color: '#848286'
        }
    }

    background: Rectangle {
        border.color : '#00ADDC'
        color: 'transparent'
    }

    function setDefaultValues() {
        isIPv4 = true
        isStatic = false
        isManualDNS = false
        staticAddress = ""
        staticNetmask = ""
        staticGateway = ""
        dnslist = ""
    }

    onIsIPv4Changed: {
        verSwitch.checked = isIPv4
    }

    onIsStaticChanged: {
        modeSwitch.checked = isStatic
    }

    onIsManualDNSChanged: {
        dnsSwitch.checked = isManualDNS
    }

    onAccepted: {
        if (isIPv4 === false) {
            console.log("IPv6 not supported by settings application")
            setDefaultValues()
        } else {
            finished(serviceName,"IPv4", staticAddress, staticNetmask, staticGateway, dnslist)
        }
    }

    onReset: {
        setDefaultValues()
    }

    Item {
        id: container
        anchors.centerIn: parent
        anchors.fill: parent
        ColumnLayout {
            anchors.fill: parent
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                spacing: 8
                visible: true
                Label {
                    id: nwLabel
                    font.pixelSize: 28
                    color: '#080C0F'
                    text: "Network:"
                    Layout.preferredWidth: 200
                }
                Label {
                    id: svcLabel
                    font.pixelSize: 28
                    color: '#66FF99'
                    text: serviceName
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                spacing: 8
                visible: true
                Label {
                    id: ipvlabel
                    font.pixelSize: 28
                    color: '#080C0F'
                    text: "IP version:"
                    Layout.preferredWidth: 200
                }
                Label {
                    id: ipv6label
                    font.pixelSize: 28
                    color: root.isIPv4? '#848286':'#0DF9FF'
                    text: "IPv6"
                    Layout.preferredWidth: 80
                }
                Switch {
                    id: verSwitch
                    scale: 0.5
                    checked : root.isIPv4
                    onCheckedChanged: { root.isIPv4 =  checked }
                }
                Label {
                    id: ipv4label
                    font.pixelSize: 28
                    color: root.isIPv4? '#0DF9FF':'#848286'
                    text: "IPv4"
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                visible: root.isIPv4? false : true
                Label {
                    font.pixelSize: 28
                    color: 'white'
                    text: "IPv6 not supported by Settings application"
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                spacing: 8
                visible: root.isIPv4? true : false
                Label {
                    id: modelabel
                    font.pixelSize: 28
                    color: '#080C0F'
                    text: "Addressing:"
                    Layout.preferredWidth: 200
                }
                Label {
                    id: dhcplabel
                    font.pixelSize: 28
                    color: root.isStatic? '#848286':'#0DF9FF'
                    text: "DHCP"
                    Layout.preferredWidth: 80
                }
                Switch {
                    id: modeSwitch
                    scale: 0.5
                    checked : root.isStatic
                    onCheckedChanged: { root.isStatic = checked }
                }
                Label {
                    id: staticlabel
                    font.pixelSize: 28
                    color: root.isStatic? '#0DF9FF':'#848286'
                    text: "Static"
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                visible: (root.isStatic && root.isIPv4)? true : false
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: address
                        font.pixelSize: 28
                        color: '#080C0F'
                        text: "address:"
                    }
                    TextField {
                        id: m_staticAddress
                        font.pixelSize: 28
                        Layout.fillWidth: true
                        placeholderText: "address"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: netmask
                        font.pixelSize: 28
                        color: '#080C0F'
                        text: "netmask:"
                    }
                    TextField {
                        id: m_staticNetmask
                        font.pixelSize: 28
                        Layout.fillWidth: true
                        placeholderText: "netmask"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: gateway
                        font.pixelSize: 28
                        color: '#080C0F'
                        text: "gateway:"
                    }
                    TextField {
                        id: m_staticGateway
                        font.pixelSize: 28
                        Layout.fillWidth: true
                        placeholderText: "gateway"
                    }
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                spacing: 8
                visible: root.isIPv4? true : false
                Label {
                    id: dnslabel
                    font.pixelSize: 28
                    color: '#080C0F'
                    text: "DNS address:"
                    Layout.preferredWidth: 200
                }
                Label {
                    id: customdnslabel
                    font.pixelSize: 28
                    color: root.isManualDNS? '#848286':'#0DF9FF'
                    text: "Auto"
                    Layout.preferredWidth: 80
                }
                Switch {
                    id: dnsSwitch
                    scale: 0.5
                    checked : root.isManualDNS
                    onCheckedChanged: { root.isManualDNS = checked }
                }
                Label {
                    id: autodnslabel
                    font.pixelSize: 28
                    color: root.isManualDNS? '#0DF9FF':'#848286'
                    text: "Manual"
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                visible: (root.isManualDNS && root.isIPv4)? true : false
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: dnsList
                        font.pixelSize: 28
                        color: '#080C0F'
                        text: "DNS list:"
                    }
                    TextField {
                        id: m_dnslist
                        font.pixelSize: 28
                        Layout.fillWidth: true
                        placeholderText: "List DNS semicolon separated"
                    }
                }
            }

            Keyboard {
                id: keyboard
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1
                target: activeFocusControl
            }
        }
    }
}
