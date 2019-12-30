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
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.4
import AGL.Demo.Controls 1.0
import ".."

SettingPage {
    id: root
    icon: '/voice/images/HMI_Settings_VoiceIcon.svg'
    title: 'Voice'
    readonly property bool isVoice: true

    Component {
        id: voiceAgent
        MouseArea {
            height: 120
            width: ListView.view.width
            Column {
                anchors.leftMargin: 100
                id: agentName
                Label {
                    id: agentNameText
                    text: name
                    color: '#66FF99'
                    font.pixelSize: 38
                    font.bold: active === "active"
                }
            }
            Column {
                anchors.right: parent.right
                anchors.rightMargin: 5
                Button {
                    visible: active === "active"
                    font.pixelSize: 18
                    text: "DETAILS"
                    onClicked: {
                        agentdata.tokenValid  = Qt.binding(function() { return (usrauth[2] === "expired")? false : true })
			agentdata.agentActive = Qt.binding(function() { return (active === "active")? true: false })
                        agentdata.open()
                   }

                   ConfigDialog {
                       id: agentdata
                       parent: Overlay.overlay
                       maxpwidth: 744
                       maxpheight: 744
                       xpos: (parent.width - maxpwidth)/2
                       ypos: (parent.height - maxpheight)/2
                       thisAgentName: name
                       thisAgentId: id
		       thisAgentWuW: wuw
		       thisAgentVendor: vendor
		       thisAgentAuthState: authstate
                       thisAgentConnState: connstate
                       thisAgentDialogState: dialogstate
                       thisAgentLoginUrl: usrauth[0]
                       thisAgentLoginCode: usrauth[1]

                       onRequestNewToken: {
                               voice.getCBLpair(id);
                       }
                   }
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
        model: VoiceAgentModel
        delegate: voiceAgent
        clip: true
    }
}
