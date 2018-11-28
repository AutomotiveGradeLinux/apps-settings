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
            bluetooth.send_confirmation(data.pincode)
        }

        onDeviceAddedEvent: {
            var id = data.device;
            var value = data.properties;

            if (value.paired === true) {
                pairedDeviceList.append({
                    deviceId: id,
                    deviceAddress: value.address,
                    deviceName: value.name,
                    devicePairable: value.paired,
                    deviceConnect: value.connected,
                })
                pairedDeviceCount = pairedDeviceCount + 1
            } else {
                btDeviceList.append({
                    deviceId: id,
                    deviceAddress: value.address,
                    deviceName: value.name,
                    devicePairable: value.paired,
                    deviceConnect: value.connected,
                })
            }
        }

        onDeviceRemovedEvent: {
            if (findDevice(data.device) >= 0) {
                btDeviceList.remove(findDevice(data.device))
            } else if(findPairDevice(data.device) >= 0) {
                pairedDeviceList.remove(findPairDevice(data.device))
                pairedDeviceCount = pairedDeviceCount - 1
            }
        }

        onDeviceUpdatedEvent: {
            updateDeviceAttribute(data)
        }

        onDeviceListEvent: {
            for (var i = 0; i < data.devices.length; i++) {
                var id = data.devices[i].device;
                var value = data.devices[i].properties;

                if (value.paired === true) {
                    if(findPairDevice(id) == -1) {
                      pairedDeviceList.append({
                                      deviceId: id,
                                      deviceAddress: value.address,
                                      deviceName: value.name,
                                      devicePairable: value.paired,
                                      deviceConnect: value.connected,
                                  })
                      pairedDeviceCount = pairedDeviceCount + 1
                    }
                  } else {
                    if (findDevice(id) == -1) {
                      btDeviceList.append({
                                       deviceId: id,
                                       deviceAddress: value.address,
                                       deviceName: value.name,
                                       devicePairable: value.paired,
                                       deviceConnect: value.connected,
                                  })
                    }
		 }
            }
        }

        onPowerChanged: {
            root.checked = state
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

        bluetooth.power = checked;
        bluetooth.discoverable = checked;

        if (checked == true) {
            bluetooth.start_discovery()
        } else {
            btDeviceList.clear()
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
                        text: deviceAddress
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
                             bluetooth.remove_device(deviceId);
                             if (findDevice(deviceId) != -1) {
                                btDeviceList.remove(findDevice(deviceId))
                             } else if (findPairDevice(deviceAddress) != -1) {
                                pairedDeviceList.remove(findPairDevice(deviceId))
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

                  text: (deviceConnect === true) ? "Disconnect" : ((devicePairable === true) ? "Connect" : "Pair")
		  MouseArea {
                     anchors.fill: parent
                     onClicked: {
                         if (connectButton.text == "Pair"){
                             bluetooth.pair(deviceId)
                         }
                         else if (connectButton.text == "Connect"){
                                  bluetooth.connect(deviceId)
                         }
                         else if (connectButton.text == "Disconnect"){
                                  bluetooth.disconnect(deviceId)
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
              if (bluetooth.power === true && pairedDeviceCount != 0)
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
	  visible: bluetooth.power
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

      function findDevice(id) {
          for (var i = 0; i < btDeviceList.count; i++) {
              if (id === btDeviceList.get(i).deviceId)
                  return i
          }
          return -1
      }
      function findPairDevice(id){
          for (var i = 0; i < pairedDeviceList.count; i++) {
              if (id === pairedDeviceList.get(i).deviceId)
                  return i
          }
          return -1
      }

      function updateDeviceAttribute(data){
            var id = data.device;
            var value = data.properties;

            for (var i = 0; i < btDeviceList.count; i++) {
                if (id === btDeviceList.get(i).deviceId){
                    btDeviceList.get(i).devicePairable = value.paired
                    if (value.paired === true)
                    {
                        pairedDeviceList.append({
                                        deviceId: btDeviceList.get(i).deviceId,
                                        deviceAddress: btDeviceList.get(i).deviceAddress,
                                        deviceName: btDeviceList.get(i).deviceName,
                                        devicePairable: btDeviceList.get(i).devicePairable,
                                        deviceConnect: btDeviceList.get(i).deviceConnect,
                                    })
                        pairedDeviceCount = pairedDeviceCount + 1
                        btDeviceList.remove(i, 1)
                    }
              }
          }

          for (var i = 0; i < pairedDeviceList.count; i++) {
               if (id === pairedDeviceList.get(i).deviceId){
                    if (value.connected !== undefined)
                        pairedDeviceList.get(i).deviceConnect = value.connected
                    if (value.paired !== undefined)
                        pairedDeviceList.get(i).devicePairable = value.paired
               }
          }
      }
}
