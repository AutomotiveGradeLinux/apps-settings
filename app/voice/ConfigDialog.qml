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
    property alias xpos: root.x
    property alias ypos: root.y
    property alias maxpwidth: root.width
    property alias maxpheight: root.height

    property string thisAgentName: undefined
    property string thisAgentId: undefined
    property string thisAgentWuW: undefined
    property string thisAgentAuthState: undefined
    property string thisAgentConnState: undefined
    property string thisAgentDialogState: undefined
    property string thisAgentLoginUrl: undefined
    property string thisAgentLoginCode: undefined
    property bool tokenValid: false
    property bool agentActive: false

    signal requestNewToken(string thisAgentId)

    visible: false
    z: 1
    focus: true
    modal: false
    footer: DialogButtonBox {
        Button { text: "CLOSE"
                 DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
        Button { text: "UPDATE"
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

    onReset: refreshToken()
    function refreshToken() {
            root.requestNewToken(thisAgentId);
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
                spacing: 32
                visible: true
                Label {
                    id: voiceLabel
                    font.pixelSize: 28
                    color: '#080C0F'
                    text: "Voice Agent:"
                    Layout.preferredWidth: 200
                }
                Label {
                    id: idLabel
                    font.pixelSize: 28
                    color: '#66FF99'
                    text: thisAgentId
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                spacing: 32
                visible: true
                Label {
                    id: namelabel
                    font.pixelSize: 28
                    color: '#080C0F'
                    text: "Assistant Name:"
                    Layout.preferredWidth: 200
                }
                Label {
                    id: aNamelabel
                    font.pixelSize: 28
                    color: '#66FF99'
                    text: thisAgentName
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                spacing: 32
                visible: true
                Label {
                    id: wuwlabel
                    font.pixelSize: 28
                    color: '#080C0F'
                    text: "Wake Up Word:"
                    Layout.preferredWidth: 200
                }
                Label {
                    id: thiswuwlabel
                    font.pixelSize: 28
                    color: '#66FF99'
                    text: thisAgentWuW
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                visible: true
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: authLabel
                        font.pixelSize: 28
                        color: '#080C0F'
                        text: "Authorization status:"
                    }
                    Label {
                        id: connlabel
                        font.pixelSize: 28
                        color: '#080C0F'
                        text: "Connection status:"
                    }
                    Label {
                        id: dialogLabel
                        font.pixelSize: 28
                        color: '#080C0F'
                        text: "Dialog status:"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: authsLabel
                        font.pixelSize: 28
                        color: (thisAgentAuthState == "UNITIALIZED")? 'red' : '#66FF99'
                        text: thisAgentAuthState
                    }
                    Label {
                        id: connslabel
                        font.pixelSize: 28
                        color: (thisAgentConnState == "DISCONNECTED")? 'red' : '#0DF9FF'
                        text: thisAgentConnState
                    }
                    Label {
                        id: dialogsLabel
                        font.pixelSize: 28
                        color: (thisAgentDialogState == "MICROPHONEOFF")? 'red' : '#0DF9FF'
                        text: thisAgentDialogState
                    }
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                visible: true
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: loginurlLabel
                        font.pixelSize: 28
                        color: '#080C0F'
                        text: "Login url:"
                    }
                    Label {
                        id: logincodeLabel
                        font.pixelSize: 28
                        color: '#080C0F'
                        text: "Login code:"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: urlLabel
                        font.pixelSize: 28
                        color: root.tokenValid? '#848286':'#0DF9FF'
                        text: thisAgentLoginUrl
                    }
                    Label {
                        id: codeLabel
                        font.pixelSize: 28
                        color: root.tokenValid? '#848286':'#0DF9FF'
                        text: thisAgentLoginCode
                    }
                }
            }
            Label {
                font.pixelSize: 18
                visible: root.tokenValid
                text: "You can use the supplied login data to enable "+thisAgentName+"."
            }
            Label {
                font.pixelSize: 18
                visible: !root.tokenValid
                text: "The current login data is not valid. Press 'UPDATE' to refresh."
            }
        }
    }
}
