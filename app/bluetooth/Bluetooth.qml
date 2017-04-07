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
import QtWebSockets 1.0
import '..'

SettingPage {
    id: root
    icon: '/bluetooth/images/HMI_Settings_BluetoothIcon.svg'
    title: 'Bluetooth'
    checkable: true

    property string btAPIpath: bindingAddress + '/Bluetooth-manager/'
    property var jsonObjectBT: []
    property string currentState: 'idle'
    property string btState: 'off' //add property to indicate the bt status
    property string initDevice: 'N'

    property string address_str: bindingAddressWS
    property string token_str: ""
    property string api_str: "Bluetooth-Manager"
    property string verb_str: ""
    property var parameterJson: 'None'
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
            var message_json = JSON.parse(message);
            //console.log("Raw response: " + message)
            //console.log("JSON response: " + message_json)
            if (message_json[0] === msgid_enu.reterr) {
                console.log("Return value is not OK!")
                return
            }
            else if ((message_json[0] === msgid_enu.event)){
                var eventContent = JSON.parse(JSON.stringify(message_json[2]))
                if (eventContent.event === "Bluetooth-Manager/device_added"){
                    //jsonObjectBT.add(eventContent.data)
                    //btDeviceList.clear()
                    console.log("BT list refreshed")
                    initDevice = 'Y'
                    btDeviceList.append({
                                        deviceAddress: eventContent.data.Address,
                                        deviceName: eventContent.data.Name,
                                        devicePairable:eventContent.data.Paired,
                                        deviceConnect: eventContent.data.Connected,
                                        connectAVP: eventContent.data.AVPConnected,
                                        connectHFP: eventContent.data.HFPConnected,
                                        textToShow: ""
                                    })
                } else if(eventContent.event === "Bluetooth-Manager/device_removed"){
                  if (findDevice(eventContent.data.Address) >= 0){
                      btDeviceList.remove(findDevice(eventContent.data.Address))
                  }
                } else if(eventContent.event === "Bluetooth-Manager/device_updated"){
                  updateDeviceAttribute(eventContent.data)
                } else if(eventContent.event === "Bluetooth-Manager/request_confirmation"){
                    request(btAPIpath + "send_confirmation?value=yes", function (o) {
                    console.log(o.responseText)
                  })
                }
            }
            if ((verb_str == "connect") || (verb_str == "refresh")) {
                token_str = message_json[3]
            } else if (verb_str == "logout") {
                token_str = ""
                websocket.active = false
                console.log("close socket")
            }
        }
        onStatusChanged: {
            if (websocket.status == WebSocket.Error) {
                status_str = "Error: " + websocket.errorString
            } else if (websocket.status == WebSocket.Open) {
                status_str = "Socket opened; sending message..."
                if (verb_str == "connect"){
                    WebSocket.sendTextMessage (request_str)
                }

                verb_str = "eventadd"
                parameterJson = {
                    tag: 'device_updated',
                    name: 'device_updated'
                }
                sendSocketMesage(verb_str, parameterJson)

                verb_str = "eventsub"
                parameterJson = {
                    tag: 'device_updated'
                }
                sendSocketMesage(verb_str, parameterJson)

                verb_str = "eventadd"
                parameterJson = {
                    tag: 'device_added',
                    name: 'device_added'
                }
                sendSocketMesage(verb_str, parameterJson)

                verb_str = "eventsub"
                parameterJson = {
                    tag: 'device_added'
                }
                sendSocketMesage(verb_str, parameterJson)

                verb_str = "eventadd"
                parameterJson = {
                    tag: 'device_removed',
                    name: 'device_removed'
                }
                sendSocketMesage(verb_str, parameterJson)

                verb_str = "eventsub"
                parameterJson = {
                    tag: 'device_removed'
                }
                sendSocketMesage(verb_str, parameterJson)

                verb_str = "eventadd"
                parameterJson = {
                    tag: 'request_confirmation',
                    name: 'request_confirmation'
                }
                sendSocketMesage(verb_str, parameterJson)

                verb_str = "eventsub"
                parameterJson = {
                    tag: 'request_confirmation'
                }
                sendSocketMesage(verb_str, parameterJson)

            } else if (websocket.status == WebSocket.Closed) {
                status_str = "Socket closed"
            }
        }
        active: false
    }

    Text {
        id: log
        anchors.fill: parent
        anchors.margins: 10
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    onCheckedChanged: {
        console.log("Bluetooth set to", checked)
        if (checked == true) {
            initBTlist()
            request(btAPIpath + 'power?value=1', function (o) {
                // log the json response
                console.log(o.responseText)
                websocket.active = true
            })
            request(btAPIpath + 'set_property?Property=Discoverable\&value=true', function (o) {
               console.log(o.responseText)
            })
            request(btAPIpath + 'set_property?Property=Pairable\&value=true', function (o) {
               console.log(o.responseText)
            })
            request(btAPIpath + 'start_discovery', function (o) {
               console.log(o.responseText)
            })
            buttonScan.text = "STOP"		//when power on and after send the discovery command, button set to STOP
            currentState = 'discovering'
            btState = 'on'	//bt is on

        } else {
            btDeviceList.clear()
            request(btAPIpath + 'stop_discovery', function (o) {
               // log the json response
               console.log(o.responseText)
            })
            request(btAPIpath + 'power?value=0', function (o) {
                // log the json response
                console.log(o.responseText)
            })
            buttonScan.text = "SEARCH"	//when power off the button should be set to SEARCH
            currentState = 'idle'
            btState = 'off'	//bt off
            websocket.active = false
        }
    }

    function sendSocketMesage(verb, parameter) {
        var requestJson = [msgid_enu.call, payloadLength, api_str + '/'
                           + verb, parameter]
        websocket.sendTextMessage(JSON.stringify(requestJson))
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
                                    console.log(o.responseText)
                                })
                                    buttonScan.text = "STOP"
                                    currentState = 'discovering'
                                }
                            }else{
                                request(btAPIpath + 'stop_discovery', function (o) {
                                    // log the json response
                                    console.log(o.responseText)
                                })
                                buttonScan.text = "SEARCH"
                                currentState = 'idle'
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
                     Text {
                        id: btStatus
                        property string connectionState:""
                        text: {
                          if ((devicePairable === "True")
                                 && (deviceConnect === "False"))
                                 text = ", paired"
                          else if ((devicePairable === "True")
                                   && (deviceConnect === "True")
                                   && (connectAVP === "True")
                                   && (connectHFP === "False"))
                                   text = " AV Connection, "
                          else if ((devicePairable === "True")
                                    && (deviceConnect === "True")
                                    && (connectHFP === "True")
                                    && (connectAVP === "False"))
                                    text = " Handsfree Connection, "
                          else if ((devicePairable === "True")
                                   && (deviceConnect === "True")
                                   && (connectHFP === "True")
                                   && (connectAVP === "True"))
                                   text = " Handsfree & AV Connection, "
                          else
                             text = connectionState
                          if (initDevice === "Y")
                          {
                             textToShow = text
                             text = deviceAddress + text
                             initDevice = 'N'
                          }
                          else
                          {
                             text = deviceAddress + textToShow
                          }
                        }
                        font.pixelSize: 18
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
                             if (findDevice(deviceAddress) >= 0){
                                btDeviceList.remove(findDevice(deviceAddress))
                             }
                         }
                     }
                 }

                 Button {
                  id: connectButton
                  anchors.top:parent.top
                  anchors.topMargin: 15
                  anchors.right: removeButton.left
                  anchors.rightMargin: 10

                  text:(deviceConnect == "True")? "Disconnect":((btPairable.text == "True")? "Connect":"Pair")
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
                             request(btAPIpath + 'set_device_property?Address=' + deviceAddress + '\&Property=Trusted\&value=true', function (o) {
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
          for (var i = 0; i < btDeviceList.count; i++) {
              if (address === btDeviceList.get(i).deviceAddress){
                  return i
                  }
              }
          return -1
      }

      function updateDeviceAttribute(data){
            var text = ""
            for (var i = 0; i < btDeviceList.count; i++) {
                if (data.Address === btDeviceList.get(i).deviceAddress){
                    btDeviceList.get(i).devicePairable = data.Paired
                    if (data.Paired == "True")
                    {
                        console.log("connectButton  " + btDeviceList.get(i).btStatus)
                        //ALCZbtDeviceList.get(i).connectButton.text = "Connect"
                    }

                    if ((data.Paired === "True")
                               && (data.Connected === "False"))
                        text = ", paired"
                    else if ((data.Paired === "True")
                               && (data.Connected === "True")
                               && (data.AVPConnected === "True")
                               && (data.HFPConnected === "False"))
                        text = "AV Connection, "
                    else if ((data.Paired === "True")
                                && (data.Connected === "True")
                                && (data.HFPConnected === "True")
                                && (data.AVPConnected === "False"))
                        text = "Handsfree Connection, "
                    else if ((data.Paired === "True")
                                && (data.Connected === "True")
                                && (data.HFPConnected === "True")
                                && (data.AVPConnected === "True")) {
                        console.log("all connected!!")
                        text = ", Handsfree & AV Connection"}
                    else
                        text = ""

                    btDeviceList.set(i, {
                                            textToShow: " " + text
                                        })
                    console.log("iamhere" + btDeviceList.get(i).deviceAddress + data.Paired)

                    //btDeviceList.get(i).btStatus = text + btDeviceList.get(i).deviceAddress //btDeviceList.get(i).textToShow
                    btDeviceList.layoutChanged()

                    btDeviceList.get(i).deviceConnect = data.Connected
                    console.log(data.Connected)
              }
          }
        }

      function initBTlist(){
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
              initDevice = 'Y'
              console.log(jsonObjectBT[i].Paired)
              btDeviceList.append({
                                      deviceAddress: jsonObjectBT[i].Address,
                                      deviceName: jsonObjectBT[i].Name,
                                      devicePairable:jsonObjectBT[i].Paired,
                                      deviceConnect: jsonObjectBT[i].Connected,
                                      connectAVP: jsonObjectBT[i].AVPConnected,
                                      connectHFP: jsonObjectBT[i].HFPConnected,
                                      textToShow: ""
                                  })
             }
          })
      }
 }

