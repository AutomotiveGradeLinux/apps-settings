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
import QtQrCode.Component 1.0
import AGL.Demo.Controls 1.0

Dialog {
    id: root
    property alias xpos: root.x
    property alias ypos: root.y
    property alias maxpwidth: root.width
    property alias maxpheight: root.height

    property string thisAgentName: undefined
    property string thisAgentId: undefined
    property string thisAgentVendor: undefined
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
    modal: true
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
        color: 'black'
        opacity: 0.5
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
            spacing: 0

            RowLayout {
                Layout.fillHeight: false
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                spacing: 16

                /* Labels */
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: nameLabel
                        font.pixelSize: 28
                        color: 'white'
                        text: "Voice Agent:"
                        Layout.preferredWidth: 200
                    }
                    Label {
                        id: vendorLabel
                        font.pixelSize: 28
                        color: 'white'
                        text: "Vendor:"
                        Layout.preferredWidth: 200
                    }
                    Label {
                        id: wuwLabel
                        font.pixelSize: 28
                        color: 'white'
                        text: "Wake Up Word:"
                        Layout.preferredWidth: 200
                    }
                    Label {
                        id: authLabel
                        font.pixelSize: 28
                        color: 'white'
                        text: "Authorization status:"
                    }
                    Label {
                        id: connLabel
                        font.pixelSize: 28
                        color: 'white'
                        text: "Connection status:"
                    }
                    Label {
                        id: dialogLabel
                        font.pixelSize: 28
                        color: 'white'
                        text: "Dialog status:"
                    }
                }

                /* Values */
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: nameValue
                        font.pixelSize: 28
                        color: '#66FF99'
                        text: thisAgentName
                    }
                    Label {
                        id: vendorValue
                        font.pixelSize: 28
                        color: '#66FF99'
                        text: thisAgentVendor
                    }
                    Label {
                        id: wuwValue
                        font.pixelSize: 28
                        color: '#66FF99'
                        text: thisAgentWuW
                    }
                    Label {
                        id: authValue
                        font.pixelSize: 28
                        color: (thisAgentAuthState == "UNINITIALIZED")? '#00ADDC' : '#848286'
                        text: thisAgentAuthState
                    }
                    Label {
                        id: connValue
                        font.pixelSize: 28
                        color: (thisAgentConnState == "DISCONNECTED")? '#00ADDC' : '#848286'
                        text: thisAgentConnState
                    }
                    Label {
                        id: dialogValue
                        font.pixelSize: 28
                        color: (thisAgentDialogState == "MICROPHONEOFF")? '#00ADDC' : '#848286'
                        text: thisAgentDialogState
                     }
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: 32
                spacing: 16
                visible: root.thisAgentAuthState !== "REFRESHED"
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: loginUrlLabel
                        font.pixelSize: 28
                        color: 'white'
                        text: "Login url:"
                    }
                    Label {
                        id: loginCodeLabel
                        font.pixelSize: 28
                        color: 'white'
                        text: "Login code:"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: loginUrlValue
                        font.pixelSize: 28
                        color: root.tokenValid? '#848286':'#0DF9FF'
                        text: thisAgentLoginUrl
                    }
                    Label {
                        id: loginCodeValue
                        font.pixelSize: 28
                        color: root.tokenValid? '#848286':'#0DF9FF'
                        text: thisAgentLoginCode
                    }
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 8

                QtQrCode {
                    /*
                     * FIXME: Generated URL is currently Alexa-specific, work around for
                     *        now by checking agent name and only displaying for Alexa.
                     */
                    data: root.thisAgentLoginUrl + '?cbl-code=' + root.thisAgentLoginCode
                    visible: root.thisAgentName === "Alexa" && root.thisAgentAuthState !== "REFRESHED" && root.tokenValid
                    background: 'white'
                    margin: 16
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
            Label {
                id: instructions
                font.pixelSize: 18

                states: [
                    State {
                        name: "HAVE_TOKEN"
                        when: root.thisAgentAuthState !== "REFRESHED" && root.tokenValid
                        PropertyChanges {
                            target: instructions
                            text: "You can use the supplied login data to enable "+thisAgentName+"."
                            visible: true
                        }
                    },
                    State {
                        name: "NEED_TOKEN"
                        when: root.thisAgentAuthState !== "REFRESHED" && !root.tokenValid
                        PropertyChanges {
                            target: instructions
                            text: "The current login data is not valid. Press 'UPDATE' to refresh."
                            visible: true
                        }
                    },
                    State {
                        name: "AUTHORIZED"
                        when: root.thisAgentAuthState === "REFRESHED"
                        PropertyChanges {
                            target: instructions
                            visible: false
                        }
                    }
                ]
            }
        }
    }
}
