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
import '..'

SettingPage {
    id: root
    icon: '/wifi/images/HMI_Settings_WifiIcon.svg'
    title: 'Wifi'
    checkable: true

    property string wifiAPIpath: bindingAddress + '/wifi-manager/'

    onCheckedChanged: {
        console.log("Wifi set to", checked)
        if (checked == true) {
            periodicRefresh.start()
            request(wifiAPIpath + 'activate', function (o) {
                // log the json response
                console.log(o.responseText)
            })

        } else {
            //console.log(networkPath)
            networkList.clear()
            request(wifiAPIpath + 'deactivate', function (o) {
                // log the json response
                console.log(o.responseText)
            })
        }
    }
    function listWifiNetworks() {
        console.log("test #4")
    }
    ListModel {
        id: networkList
    }

    function request(url, callback) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = (function (myxhr) {
            return function () {
                if (xhr.readyState == 4 && xhr.status == 200)
                    callback(myxhr)
            }
        })
        (xhr)
        xhr.open('GET', url, false)
        xhr.send('')
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
                    font.bold: serviceState === "ready" || serviceState === "online"
                }
                Label {
                    visible: serviceState === "ready" || serviceState === "online"
                    text: "connected, " + address
                    font.pointSize: 18
                    color: "white"
                    //font.italic: true
                }
            }

            onClicked: {
                //connectButton.border.color = "steelblue"
                if ((serviceState === "ready")
                        || serviceState === "online") {

                    //means we are connected
                    console.log("Disconnecting from", index, " ,", name)
                    request(wifiAPIpath + 'disconnect?network=' + index,
                            function (o) {

                                //showRequestInfo(o.responseText)
                                console.log(o.responseText)
                            })
                } else {
                    console.log("Conect to", index, " ,", name)
                    view.currentIndex = model.index
                    if (securityType(security) === "unsecured") {
                        request(wifiAPIpath + 'connect?network=' + view.currentIndex,
                                function (o) {

                                    // log the json response
                                    //showRequestInfo(o.responseText)
                                    console.log(o.responseText)
                                })
                    } else {
                        dialog.visible = true
                    }
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
        model: networkList //WifiList {}
        delegate: wifiDevice
        clip: true
    }

    MouseArea {
        id: dialog
        anchors.fill: parent
        visible: false
        z: 1
        onVisibleChanged: if (visible) password.forceActiveFocus()
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

                            console.log("Passkey is", passkey)
                            request(wifiAPIpath + 'security?passkey=' + passkey,
                                    function (o) {

                                        //showRequestInfo(o.responseText)
                                        console.log(o.responseText)
                                    })
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

    //Timer for periodic refresh; this is BAD solution, need to figure out how to subscribe for events
    Timer {
        id: periodicRefresh
        interval: 1000 // 1second
        running: !dialog.visible
        onTriggered: {

            networkList.clear()
            request(wifiAPIpath + 'scan_result', function (o) {
                // log the json response
                console.log(o.responseText)

                // translate response into object
                var jsonObject = JSON.parse(o.responseText)
                var jsonObjectNetworks = jsonObject.response
                console.log("WiFi list refreshed")
                //console.log(jsonObject.response)
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
            })
            start()
        }
    }
}
