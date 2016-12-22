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
import '..'

SettingPage {
    id: root
    icon: '/bluetooth/images/HMI_Settings_BluetoothIcon.svg'
    title: 'Bluetooth'
    checkable: true

    property string protocol: 'http://'
    property string ipAddress: '127.0.0.1'
    property string portNumber: Qt.application.arguments[1]
    property string tokenString: Qt.application.arguments[2]
    property string btAPI: '/api/Bluetooth-manager/'
    property string btAPIpath: protocol + ipAddress + ':' + portNumber + btAPI
    property var jsonObjectBT
    property string currentState: 'idle'
    property string btState: 'off' //add property to indicate the bt status

    Text {
        id: log
        anchors.fill: parent
        anchors.margins: 10
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        //text: "log"
    }

    onCheckedChanged: {
        console.log("Bluetooth set to", checked)
        if (checked == true) {
            request(btAPIpath + 'power?value=1', function (o) {
                // log the json response
                console.log(o.responseText)
            })
            request(btAPIpath + 'start_discovery', function (o) {
               console.log(o.responseText)
            })
            buttonScan.text = "STOP"		//when power on and after send the discovery command, button set to STOP
            currentState = 'discovering'
            btState = 'on'	//bt is on
            //search_device()
            periodicRefresh.start()

        } else {
            //console.log(networkPath)
            btDeviceList.clear()
            periodicRefresh.stop()
            request(btAPIpath + 'stop_discovery', function (o) {
               // log the json response
               console.log(o.responseText)
            })
            request(btAPIpath + 'power?value=0', function (o) {
                // log the json response
                //showRequestInfo(o.responseText)
                console.log(o.responseText)
            })
            buttonScan.text = "SEARCH"	//when power off the button should be set to SEARCH
            currentState = 'idle'
            btState = 'off'	//bt off
        }
    }

    ListModel {
      id: btDeviceList
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.margins: 80
      width: buttonScan.width + 10
      height: buttonScan.height + 10
      color: "#222"
      border.color: "white"

                Button {
                    id: buttonScan
                    anchors.centerIn: parent
                    width: 100
                    text: "SEARCH"	//default value is SEARCH

                    MouseArea {
                        //id: mouseArea
                        anchors.fill: parent

                        onClicked: {
                            if (buttonScan.text == "SEARCH"){
                                if (btState == 'on'){	//only response to the requirement when bt is on
                                    request(btAPIpath + 'start_discovery', function (o) {

                                    // log the json response
                                    //showRequestInfo(o.responseText)
                                    console.log(o.responseText)
                                })
                                    buttonScan.text = "STOP"
                                    currentState = 'discovering'
                                    periodicRefresh.start()
                                }

                            }else{
                                request(btAPIpath + 'stop_discovery', function (o) {

                                    // log the json response
                                    //showRequestInfo(o.responseText)
                                    console.log(o.responseText)
                                })
                                buttonScan.text = "SEARCH"
                                currentState = 'idle'
                                //periodicRefresh.stop()  //in order to update the content from bluez
                            }
                        }
                    }
                }
      }

      function request(url, callback) {
            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = (function (myxhr) {
            return function () {
                     if (xhr.readyState == 4 && xhr.status == 200){
                         callback(myxhr)
                     }
                 }
             })(xhr)
             xhr.open('GET', url, false)
             xhr.send('')
       }

      Component {
         id:blueToothDevice
         Rectangle {
         height: 120
         width: parent.width
         color: "transparent"
             MouseArea {
               anchors.fill: parent
                 Column {
                     anchors.left: parent.left
                     anchors.leftMargin: 80
                     Text {
                        id: btName
                        text: deviceName
                        color: '#66FF99'
                        font.pixelSize: 48
                     }
//                     Text {
//                        id: btAddr
//                        text: deviceAddress
//                        font.pixelSize: 24
//                        color: 'white'
//                     }
                     Text {
                        text: {
                          if ((devicePairable === "True")
                                 && (deviceConnect === "False"))
                                 text = "paired, "
                          else if ((devicePairable === "True")
                                   && (deviceConnect === "True")
                                   && (connectAVP === "True")
                                   && (connectHFP === "False"))
                                   text = "AV Connection, "
                          else if ((devicePairable === "True")
                                    && (deviceConnect === "True")
                                    && (connectHFP === "True")
                                    && (connectAVP === "False"))
                                    text = "Handsfree Connection, "
                          else if ((devicePairable === "True")
                                   && (deviceConnect === "True")
                                   && (connectHFP === "True")
                                   && (connectAVP === "True"))
                                   text = "Handsfree & AV Connection, "
                          else
                             text = ""
                          text = text + deviceAddress
                        }
                        font.pointSize: 18
                        color: "#ffffff"
                        font.italic: true
                     }
                     Text {
                       id: btPairable
                       text: devicePairable
                       visible: false
                     }
                     Text {
                       id: btConnectstatus
                       text: deviceConnect
                       visible: false
                     }

                 }
                 Button {
                     id: removeButton
                     anchors.top:parent.top
                     anchors.topMargin: 15
                     //anchors.horizontalCenter: btName.horizontalCenter
                     anchors.right: parent.right
                     anchors.rightMargin: 100

                     text: "Unpair"
                     MouseArea {
                         anchors.fill: parent
                         onClicked: {
                             request(btAPIpath + 'remove_device?value=' + deviceAddress, function (o) {
                                 console.log(o.responseText)
                             })
                             btDeviceList.remove(findDevice(deviceAddress))
                         }
                     }

                 }

                 Button {
                  id: connectButton
                  anchors.top:parent.top
                  anchors.topMargin: 15
                  //anchors.horizontalCenter: btName.horizontalCenter
                  anchors.right: removeButton.left
                  anchors.rightMargin: 10

                  text:((connectHFP === "True") || (connectAVP === "True"))? "Disconnect":((btPairable.text == "True")? "Connect":"Pair")
                  // only when HFP or AVP is connected, button will be shown as Disconnect
		  MouseArea {
                     anchors.fill: parent
                     onClicked: {
                        if (currentState == 'discovering'){
                             request(btAPIpath + 'stop_discovery', function (o) {
                               currentState = "idle"
                               console.log(o.responseText)
                             })
                           }
                        if (connectButton.text == "Pair"){
                             connectButton.text = "Connect"
                             request(btAPIpath + 'pair?value=' + deviceAddress, function (o) {
                             btPairable.text = "True"
                                console.log(o.responseText)
                             })
                             request(btAPIpath + 'set_property?Address=' + deviceAddress + '\&Property=Trusted\&value=true', function (o) {
                                console.log(o.responseText)
                             })
                         }
                         else if (connectButton.text == "Connect"){
                                  connectButton.text = "Disconnect"
                                  request(btAPIpath + 'connect?value=' + deviceAddress, function (o) {
                                    console.log(o.responseText)
                                  })
                         }
                         else if (connectButton.text == "Disconnect"){
                                  request(btAPIpath + 'disconnect?value=' + deviceAddress, function (o) {
                                    console.log(o.responseText)
                                  })
                                  connectButton.text = "Connect"
                                  btDeviceList.remove(findDevice(deviceAddress))
                          }
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
          width: parent.width
          anchors.top: parent.top
          anchors.topMargin: 70
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 150
          model: btDeviceList
          delegate: blueToothDevice
          clip: true
      }

      function findDevice(address){
                for (var i = 0; i < jsonObjectBT.length; i++) {
                    if (address === jsonObjectBT[i].Address){
                        return i
                }
          }
      }
      function search_device(){
                btDeviceList.clear()
                request(btAPIpath + 'discovery_result', function (o) {

                    // log the json response
                    console.log(o.responseText)

                    // translate response into object
                    var jsonObject = eval('(' + o.responseText + ')')

                    jsonObjectBT = eval('(' + JSON.stbtPairableringify(
                                                      jsonObject.response) + ')')

                    console.log("BT list refreshed")

                    //console.log(jsonObject.response)
                    for (var i = 0; i < jsonObjectBT.length; i++) {
                    btDeviceList.append({
                                            deviceAddress: jsonObjectBT[i].Address,
                                            deviceName: jsonObjectBT[i].Name,
                                            devicePairable:jsonObjectBT[i].Paired,
                                            deviceConnect: jsonObjectBT[i].Connected,
                                            connectAVP: jsonObjectBT[i].AVPConnected,
                                            connectHFP: jsonObjectBT[i].HFPConnected
                                        })
                     }
               })
      }

      //Timer for periodic refresh; this is BAD solution, need to figure out how to subscribe for events
      Timer {
                id: periodicRefresh
                interval: (currentState == "idle")? 10000:1000 // 1second
                onTriggered: {

                    btDeviceList.clear()

                    request(btAPIpath + 'discovery_result', function (o) {

                        // log the json response
                        console.log(o.responseText)

                        // translate response into object
                        var jsonObject = eval('(' + o.responseText + ')')

                        jsonObjectBT = eval('(' + JSON.stringify(
                                                          jsonObject.response) + ')')

                        console.log("BT list refreshed")

                        //console.log(jsonObject.response)
                        for (var i = 0; i < jsonObjectBT.length; i++) {
                        btDeviceList.append({
                                                deviceAddress: jsonObjectBT[i].Address,
                                                deviceName: jsonObjectBT[i].Name,
                                                devicePairable:jsonObjectBT[i].Paired,
                                                deviceConnect: jsonObjectBT[i].Connected,
                                                connectAVP: jsonObjectBT[i].AVPConnected,
                                                connectHFP: jsonObjectBT[i].HFPConnected
                                            })
                       }
                    })
                    start()
                }
            }
 }

