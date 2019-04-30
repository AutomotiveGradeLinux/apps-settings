/*
 * Copyright (C) 2016 The Qt Company Ltd.
 * Copyright (C) 2018 Konsulko Group
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

import QtQuick 2.6
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0
import AGL.Demo.Controls 1.0
import ".."

SettingPage {
    id: root
    icon: '/wifi/images/HMI_Settings_WifiIcon.svg'
    title: 'Wifi'
    checkable: true
    checked: WifiAdapter.wifiEnabled
    readonly property bool isWifi: true

    onCheckedChanged: {
        network.power(checked,"wifi")
    }

    Component {
        id: wifiDevice
        MouseArea {
            height: 120
            width: ListView.view.width
            Image {
                anchors.left: parent.left
                id: icon
                source: {
                    var svg
                    if (strength < 30)
                        svg = "1Bar"
                    else if (strength < 50)
                        svg = "2Bars"
                    else if (strength < 70)
                        svg = "3Bars"
                    else
                        svg = "Full"
                    if (security === "none") {
                        return 'images/HMI_Settings_Wifi_%1.svg'.arg(svg)
                    } else {
                        return 'images/HMI_Settings_Wifi_Locked_%1.svg'.arg(svg)
                    }
                }
            }
            Column {
                anchors.left: icon.right
                anchors.leftMargin: 5
                id: networkName
                Label {
                    id: networkNameText
                    text: ssid
                    color: '#66FF99'
                    font.pixelSize: 48
                    font.bold: sstate === "ready"
                               || sstate === "online"
                }
                Label {
                    visible: sstate === "ready"
                             || sstate === "online"
                    text: "connected, " + address
                    font.pixelSize: 18
                    color: "white"
                }
            }
            Column {
                anchors.left: networkName.right
                anchors.leftMargin: 50
                Button {
                    visible: sstate === "ready"
                             || sstate === "online"
                    text: 'Forget Network'
                    onClicked: {
                        console.log("Removing network ", ssid, " (", service, ")")
                        networkNameText.font.italic = 0
                        network.remove(service)
                    }
                }
            }
            onClicked: {
                if ((sstate === "ready") || sstate === "online") {
                    console.log("Disconnecting from ", ssid, " (", service, ")")
                    networkNameText.font.italic = 1
                    network.disconnect(service)
                } else {
                    console.log("Connecting to ", ssid, " (", service, ")")
                    networkNameText.font.italic = 1
                    password.text = ''
                    network.connect(service)
                }
            }

            Image {
                source: '../images/HMI_Settings_DividingLine.svg'
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: -15
                visible: model.index > 0
            }
        }
    }

    ListView {
        id: view
        anchors.fill: parent
        anchors.margins: 100
        model: WifiNetworkModel
        delegate: wifiDevice
        clip: true
    }

    MouseArea {
        id: dialog
        anchors.fill: parent
        visible: false
        z: 1
        onVisibleChanged: {
            if (visible) {
                password.forceActiveFocus()
                root.checkable = false
            } else {
                root.checkable = true
            }
        }

        ColumnLayout {
            anchors.fill: parent
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1
                Rectangle {
                    anchors.fill: parent
                    color: 'black'
                    opacity: 0.5
                }
                RowLayout {
                    anchors.centerIn: parent
                    TextField {
                        id: password
                        property int reqid: 0
                        placeholderText: 'Password'
                    }
                    Button {
                        text: 'Connect'
                        highlighted: true
                        onClicked: {
                            network.input(password.reqid, password.text)
                            dialog.visible = false
                        }
                    }
                    Button {
                        text: 'Cancel'
                        onClicked: {
                            dialog.visible = false
                            password.text = ''
                            network.input(password.reqid, '')
                        }
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

    Connections {
        target: network
        onInputRequest: {
            password.reqid = id
            dialog.visible = true
        }

        onInvalidPassphrase: {
            if (password.text != '') {
                console.log("Invalid passphrase for (", service, ")")
                network.connect(service)
            }
        }
    }
}
