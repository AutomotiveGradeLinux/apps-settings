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
    readonly property bool isBluetooth: true
    property int pairedDeviceCount: 0

    Connections {
        target: bluetooth
        onRequestConfirmationEvent: {
            bluetooth.send_confirmation()
        }

        onDeviceAddedEvent: {
            if (data.Paired === "True") {
                pairedDeviceList.append({
                    deviceAddress: data.Address,
                    deviceName: data.Name,
                    devicePairable: data.Paired,
                    deviceConnect: data.Connected,
                    connectAVP: data.AVPConnected,
                    connectHFP: data.HFPConnected,
                    textToShow: ""
                })
                pairedDeviceCount = pairedDeviceCount + 1
            } else {
                btDeviceList.append({
                    deviceAddress: data.Address,
                    deviceName: data.Name,
                    devicePairable: data.Paired,
                    deviceConnect: data.Connected,
                    connectAVP: data.AVPConnected,
                    connectHFP: data.HFPConnected,
                    textToShow: ""
                })
            }
        }

        onDeviceRemovedEvent: {
            if (findDevice(data.Address) >= 0) {
                btDeviceList.remove(findDevice(data.Address))
            } else if(findPairDevice(data.Address) >= 0) {
                pairedDeviceList.remove(findPairDevice(data.Address))
                pairedDeviceCount = pairedDeviceCount - 1
            }
        }

        onDeviceUpdatedEvent: {
            updateDeviceAttribute(data)
        }

        onDeviceListEvent: {
            for (var i = 0; i < data.list.length; i++) {
                var value = data.list[i]
                if (value.Paired==="True") {
                    if(findPairDevice(value.Address) == -1) {
                      pairedDeviceList.append({
                                      deviceAddress: value.Address,
                                      deviceName: value.Name,
                                      devicePairable:value.Paired,
                                      deviceConnect: value.Connected,
                                      connectAVP: value.AVPConnected,
                                      connectHFP: value.HFPConnected,
                                      textToShow: ""
                                  })
                      pairedDeviceCount = pairedDeviceCount + 1
                    }
                  }
                else
                  if (findDevice(value.Address) == -1) {
                      btDeviceList.append({
                                       deviceAddress: value.Address,
                                       deviceName: value.Name,
                                       devicePairable:value.Paired,
                                       deviceConnect: value.Connected,
                                       connectAVP: value.AVPConnected,
                                       connectHFP: value.HFPConnected,
                                       textToShow: ""
                                  })
                  }
            }
        }

        onPowerChanged: {
            root.checked = bluetooth.power
        }
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

        pairedDeviceCount = 0
        bluetooth.power = checked;
        bluetooth.discoverable = checked;

        if (checked == true) {
            bluetooth.start_discovery()
        } else {
            btDeviceList.clear()
            pairedDeviceList.clear()
            bluetooth.stop_discovery()
        }
    }

    ListModel {
      id: pairedDeviceList
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
                    text: bluetooth.discoverable ? "STOP" :"SEARCH"

                    MouseArea {
                        //id: mouseArea
                        anchors.fill: parent

                        onClicked: {
                            if (bluetooth.discoverable === false && bluetooth.power === true) {
                                    bluetooth.start_discovery()
                                    bluetooth.discoverable = true;
                            } else {
                                    bluetooth.stop_discovery()
                                    bluetooth.discoverable = false;
                            }
                        }
                    }
                }
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
                     TextMetrics {
                        id: textMetrics
                        font.family: "Arial"
                        elide: Text.ElideRight
                        elideWidth: 140
                        text: deviceName
                     }
                     Text {
                        id: btName
                        text: textMetrics.elidedText
                        color: '#66FF99'
                        font.pixelSize: 48
                     }
                     Text {
                        id: btStatus
                        property string connectionState:""
                        text: {
                           if ((devicePairable === "True")
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

                            text = deviceAddress + text
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

                     text: "Remove"
                     MouseArea {
                         anchors.fill: parent
                         onClicked: {
                             bluetooth.remove_device(deviceAddress);
                             if (findDevice(deviceAddress) != -1) {
                                btDeviceList.remove(findDevice(deviceAddress))
                             } else if (findPairDevice(deviceAddress) != -1) {
                                pairedDeviceList.remove(findPairDevice(deviceAddress))
                                pairedDeviceCount = pairedDeviceCount - 1
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

                  text: (deviceConnect == "True") ? "Disconnect" : ((btPairable.text == "True") ? "Connect" : "Pair")
                  // only when HFP or AVP is connected, button will be shown as Disconnect
		  MouseArea {
                     anchors.fill: parent
                     onClicked: {
                        if (connectButton.text == "Pair"){
                             connectButton.text = "Connect"
                             bluetooth.pair(deviceAddress)
                             btPairable.text = "True"
                         }
                         else if (connectButton.text == "Connect"){
                                  connectButton.text = "Disconnect"
                                  bluetooth.connect(deviceAddress)
                         }
                         else if (connectButton.text == "Disconnect"){
                                  bluetooth.disconnect(deviceAddress)
                                  connectButton.text = "Connect"
                          }
                      }
                    }
                }
             }
          }
      }
      Text {
          id: pairedlabel
          width: parent.width
          anchors.top: parent.top
          anchors.topMargin: 50
          anchors.left: parent.left
          anchors.leftMargin: 80
          height: 80
          color:'grey'
          font.pixelSize: 30
          text:{
              if (bluetooth.power == true && pairedDeviceCount != 0)
                    "LIST OF PAIRED DEVICES"
              else
                    ""
          }
      }
      ListView{
          id: pairedListView
          width: parent.width
          anchors.top: pairedlabel.bottom
          anchors.bottom: pairedlabel.bottom
          anchors.bottomMargin: (-120*pairedDeviceCount)
          model: pairedDeviceList
          delegate: blueToothDevice
          clip: true
      }
      Image {
          anchors.bottom: pairedListView.bottom
          anchors.left: parent.left
          anchors.leftMargin: 80
          height: 5
          source: (bluetooth.power === true && pairedDeviceCount != 0) ? '../images/HMI_Settings_DividingLine.svg':''
      }
      Text {
          id: detectedlabel
          width: parent.width
          anchors.top: pairedListView.bottom
          anchors.topMargin: (pairedDeviceCount != 0) ? 80:-80
          anchors.left: parent.left
          anchors.leftMargin: 80
          height: 80
          color:'grey'
          font.pixelSize: 30
          text: {
              if (bluetooth.power === true)
                  "LIST OF DETECTED DEVICES"
              else
                  ""
          }
      }
      ListView {
          id:listView2
          width: parent.width
          anchors.top: detectedlabel.bottom
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 150
          model: btDeviceList
          delegate: blueToothDevice
          clip: true
      }

      function findDevice(address) {
          for (var i = 0; i < btDeviceList.count; i++) {
              if (address === btDeviceList.get(i).deviceAddress)
                  return i
          }
          return -1
      }
      function findPairDevice(address){
          for (var i = 0; i < pairedDeviceList.count; i++) {
              if (address === pairedDeviceList.get(i).deviceAddress)
                  return i
          }
          return -1
      }

      function updateDeviceAttribute(data){
            var text = ""
            for (var i = 0; i < btDeviceList.count; i++) {
                if (data.Address === btDeviceList.get(i).deviceAddress){
                    btDeviceList.get(i).devicePairable = data.Paired
                    if (data.Paired === "True")
                    {
                        pairedDeviceList.append({
                                        deviceAddress: btDeviceList.get(i).deviceAddress,
                                        deviceName: btDeviceList.get(i).deviceName,
                                        devicePairable:btDeviceList.get(i).devicePairable,
                                        deviceConnect: btDeviceList.get(i).deviceConnect,
                                        connectAVP: btDeviceList.get(i).connectAVP,
                                        connectHFP: btDeviceList.get(i).connectHFP,
                                        textToShow: ""
                                    })
                        pairedDeviceCount = pairedDeviceCount + 1
                        btDeviceList.remove(i, 1)
                        btDeviceList.layoutChanged()
                    }
                    else{
                        text=deviceConnectionAttribute(data)
                        btDeviceList.set(i, {
                                            textToShow: " " + text
                                        })

                        btDeviceList.layoutChanged()

                        btDeviceList.get(i).deviceConnect = data.Connected
                        console.log(data.Connected)
                    }

              }
          }
            for (var i = 0; i < pairedDeviceList.count; i++) {
               if(data.Address === pairedDeviceList.get(i).deviceAddress){
                    pairedDeviceList.get(i).devicePairable = data.Paired

                    text=deviceConnectionAttribute(data)
                    pairedDeviceList.set(i, { textToShow: " " + text })

                    pairedDeviceList.layoutChanged()

                    pairedDeviceList.get(i).deviceConnect = data.Connected
               }
            }
        }

      function deviceConnectionAttribute(data){
          var text = ""
          if ((data.Paired === "True")
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
          return text
      }
}
