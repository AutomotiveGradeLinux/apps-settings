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

import QtQuick 2.6
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0
import AGL.Demo.Controls 1.0
import ".."

SettingPage {
    id: root
    icon: '/wired/images/HMI_Settings_WiredIcon.svg'
    title: 'Wired'
    readonly property bool isWired: true

    Component {
        id: wiredDevice
        MouseArea {
            height: 120
            width: ListView.view.width
            Column {
                anchors.left: parent.left
                anchors.leftMargin: 5
                id: networkName
                Label {
                    id: networkNameText
                    text: service
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
            onClicked: {
                if ((sstate === "ready") || sstate === "online") {
                    console.log("Disconnecting from ->", service)
                    networkNameText.font.italic = 1
                    network.disconnect(service)
                } else {
                    console.log("Connecting to ->", service)
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
        model: WiredNetworkModel
        delegate: wiredDevice
        clip: true
    }

    Connections {
        target: network
        onInputRequest: {
                console.log("Only unatheunticated access implemented for (", service, ")")
        }

    }
}
