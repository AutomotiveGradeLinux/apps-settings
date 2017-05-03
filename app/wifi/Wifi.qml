
/*
 * Copyright (C) 2016 The Qt Company Ltd.
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
import QtWebSockets 1.0
import ".."

SettingPage {
    id: root
    icon: '/wifi/images/HMI_Settings_WifiIcon.svg'
    title: 'Wifi'
    checkable: true
    readonly property bool isWifi: true
    property bool isInitializing: true

    property string wifiAPIpath: bindingAddress + '/wifi-manager/'
    //http://localhost:12345/api

    property string address_str: bindingAddressWS

    property string token_str: ""
    property string api_str: "wifi-manager"
    property string verb_str: ""
    property string parameter_str: ""
    property string payloadLength: "9999"

    property var msgid_enu: {
         "call": 2,
         "retok": 3,
         "reterr": 4,
         "event": 5
    }
    property string request_str: ""
    property string status_str: ""



    WebSocket {
        id: websocket
        url: address_str
        onTextMessageReceived: {
            var message_json = JSON.parse(message)
            console.debug("Raw response: " + message)
            /* server is not happy with our request, ignore it */
            if ((message_json[0] === msgid_enu.reterr)) {

                console.error("Return value is not OK!")
                console.error("Raw response: " + message)
                return

            } else if ((message_json[0] === msgid_enu.event)) {

                var eventContent = JSON.parse(JSON.stringify(message_json[2]))

                console.log("Received EVENT: " + eventContent.event)

                if (eventContent.event === "wifi-manager/networkListUpdated") {

                    console.debug("Event data:" + eventContent.data.data1 + ", " + eventContent.data.data2 )
                    console.log("Network List was updated, sending scan_result request")

                    //update network list
                    verb_str = "scan_result"
                    var parameterJson = 'None'
                    sendSocketMesage(verb_str, parameterJson)
                }

                else if (eventContent.event === "wifi-manager/passkeyQuery") {

                    console.debug("Event data:" + eventContent.data.data1 + ", " + eventContent.data.data2 )
                    console.log("Passkey requested")
                    dialog.visible = true

                }
                else {

                    console.error("Unhadled event.")

                }
            } else if ((message_json[0] === msgid_enu.retok)) {


                /* token creation or refresh happened, store it and enable buttons */
                if (verb_str == "connect") {
                    token_str = message_json[3]

                    console.error("Connect reply received!")


                } else if (verb_str == "logout") {
                    websocket.active = false // close the socket

                } else if (verb_str == "scan_result") {

                    var jsonObjectNetworks = JSON.parse(
                                JSON.stringify(message_json[2].response))

                    networkList.clear()
                    for (var i = 0; i < jsonObjectNetworks.length; i++) {

                        networkList.append({
                                               number: jsonObjectNetworks[i].Number,
                                               name: jsonObjectNetworks[i].ESSID,
                                               strength: jsonObjectNetworks[i].Strength,
                                               serviceState: jsonObjectNetworks[i].State,
                                               security: jsonObjectNetworks[i].Security,
                                               address: jsonObjectNetworks[i].IPAddress
                                           })
                    }

                }
                else if (verb_str == "status") {

                    var status = "OFF"
                    status =  (message_json[2].response).Power

                    checked = (status === "ON") ? true : false
              }
            } else
                console.log("Unhadled websocket message", message_json[0])
        }
        onStatusChanged: {

            var parameterJson = 0
            var requestJson = 0

            if (websocket.status == WebSocket.Error) {
                status_str = "Error: " + websocket.errorString

            } else if (websocket.status == WebSocket.Open) {
                status_str = "Socket opened; sending message..."

                //first get the status
                verb_str = "status"
                parameterJson = 'None'
                sendSocketMesage(verb_str, parameterJson)



            } else if (websocket.status == WebSocket.Closed) {
                status_str = "Socket closed"
                console.log("Socket closed, bye.")

                websocket.active = false

            }

            console.log(status_str)
        }
        active: false
    }

    onCheckedChanged: {
        console.log("Wifi set to", checked)

        if (websocket.active) {

            if (checked == true) {

                //subscribe for events
                var parameterJson

                //network list updated event
                verb_str = "eventadd"
                parameterJson = {
                    tag: 'networkList',
                    name: 'networkListUpdated'
                }
                sendSocketMesage(verb_str, parameterJson)


                //TODO: send this ONLY when OK response is received
                verb_str = "eventsub"
                parameterJson = {
                    tag: 'networkList'
                }
                sendSocketMesage(verb_str, parameterJson)


                //passkey required event
                verb_str = "eventadd"
                parameterJson = {
                    tag: 'passkey',
                    name: 'passkeyQuery'
                }
                sendSocketMesage(verb_str, parameterJson)


                //TODO: send this ONLY when OK response is received
                verb_str = "eventsub"
                parameterJson = {
                    tag: 'passkey'
                }
                sendSocketMesage(verb_str, parameterJson)


                verb_str = "activate"
                parameterJson = 'None'
                sendSocketMesage(verb_str, parameterJson)


                //get scan results right away
                verb_str = "scan_result"
                parameterJson = 'None'
                sendSocketMesage(verb_str, parameterJson)

            } else {

                if (!isInitializing) {

                    networkList.clear()

                    verb_str = "deactivate"
                    parameterJson = 'None'
                    sendSocketMesage(verb_str, parameterJson)


                    verb_str = "eventunsub"
                    parameterJson = {
                        tag: 'passkey'
                    }
                    sendSocketMesage(verb_str, parameterJson)

                    verb_str = "eventdel"
                    parameterJson = {
                        tag: 'passkey'
                    }
                    sendSocketMesage(verb_str, parameterJson)

                    verb_str = "eventunsub"
                    parameterJson = {
                    tag: 'networkList'
                    }
                    sendSocketMesage(verb_str, parameterJson)

                    verb_str = "eventdel"
                    parameterJson = {
                    tag: 'networkList'
                    }
                    sendSocketMesage(verb_str, parameterJson)

                }
             }
            isInitializing = false
        }

        else {
            console.log("Websocket not active.")
            websocket.active = true
        }



    }


    function sendSocketMesage(verb, parameter) {


        var requestJson = [msgid_enu.call, payloadLength, api_str + '/'
                           + verb, parameter]

        websocket.sendTextMessage(JSON.stringify(requestJson))

    }
    ListModel {
        id: networkList
    }


    function securityType(security) {
        if (security === "Open")
            return "unsecured"
        else
            return "secured"
    }

    Component {
        id: wifiDevice
        MouseArea {
            height: 120
            width: ListView.view.width
            Image {
                anchors.left: parent.left
                //width: 70
                //height: 50
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
                    if (securityType(security) === "unsecured") {
                        return 'images/HMI_Settings_Wifi_%1.svg'.arg(svg)
                    } else {
                        return 'images/HMI_Settings_Wifi_Locked_%1.svg'.arg(svg)
                    }
                }
            }
            Column {
                anchors.left: icon.right
                anchors.leftMargin: 5
                Label {
                    id: networkNameText
                    text: name
                    color: '#66FF99'
                    font.pixelSize: 48
                    font.bold: serviceState === "ready"
                               || serviceState === "online"
                }
                Label {
                    visible: serviceState === "ready"
                             || serviceState === "online"
                    text: "connected, " + address
                    font.pixelSize: 18
                    color: "white"
                    //font.italic: true
                }
            }



            onClicked: {
                var parameterJson = 0
                var requestJson = 0

                //connectButton.border.color = "steelblue"
                if ((serviceState === "ready") || serviceState === "online") {


                    //means we are connected
                    console.log("Disconnecting from", index, " ,", name)

                    //make some indication that disconnection is in progress
                    //probably not good enough, though. TODO: make it better
                    networkNameText.font.italic = 1

                    verb_str = "disconnect"
                    parameterJson = {
                        network: view.currentIndex
                    }
                    sendSocketMesage(verb_str, parameterJson)




                } else {
                    console.log("Requesting connection to network #", index, ", ", name, ".")
                    view.currentIndex = model.index

                    //make some indication that connection is in progress
                    //probably not good enough, though. TODO: make it better
                    networkNameText.font.italic = 1

                    verb_str = "connect"
                    parameterJson = {
                        network: view.currentIndex
                    }
                    sendSocketMesage(verb_str, parameterJson)

                }
            }


            //            ImageButton {
            //                anchors.verticalCenter: parent.verticalCenter
            //                anchors.right: parent.right
            //                offImage: '../images/HMI_Settings_X.svg'
            //                onClicked: {

            //                }
            //            }
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
        model: networkList
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
            } else {
                password.text = ''
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
                        placeholderText: 'Password'
                    }
                    Button {
                        text: 'Connect'
                        highlighted: true
                        onClicked: {

                            var passkey = password.text
                            console.log("Validating", passkey)

                            //just send the passkey, binder is waiting for it
                            verb_str = "insertpasskey"
                            var parameterJson = {
                                passkey: passkey
                            }
                            sendSocketMesage(verb_str, parameterJson)
                            dialog.visible = false
                        }
                    }
                    Button {
                        text: 'Cancel'
                        onClicked: dialog.visible = false
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

    function activateWifi(){
        websocket.active = true
    }

}
