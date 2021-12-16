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
    readonly property bool isBluetooth: true

    Component.onCompleted : {
        bluetooth.start()
    }

    Connections {
        target: bluetooth
        onRequestConfirmationEvent: {
            // If a dialog were to be display to confirm the PIN it
            // could be triggered here.
            bluetooth.send_confirmation(pincode)
        }

        onPowerChanged: {
            console.log("onPowerChanged - state ", state)
            if (state) {
                bluetooth.start_discovery()
                bluetooth.discoverable = true;
            }
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
        bluetooth.power = checked
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.margins: 80
      width: 110
      color: "#222"
      border.color: "white"

                Button {
                    id: buttonScan
                    anchors.centerIn: parent
                    anchors.margins: 10
                    text: bluetooth.discoverable ? "STOP" :"SEARCH"
                    visible: bluetooth.power

                    MouseArea {
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
         id: blueToothDevice
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
                        text: name
                     }
                     Text {
                        text: textMetrics.elidedText
                        color: '#66FF99'
                        font.pixelSize: 48
                     }
                     Text {
                        text: address
                        font.pixelSize: 18
                        color: "#ffffff"
                        font.italic: true
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
                             bluetooth.remove_device(id);
                         }
                     }
                 }

                 Button {
                  id: connectButton
                  anchors.top:parent.top
                  anchors.topMargin: 15
                  anchors.right: removeButton.left
                  anchors.rightMargin: 10

                  text: (connected === true) ? "Disconnect" : ((paired === true) ? "Connect" : "Pair")
		  MouseArea {
                     anchors.fill: parent
                     onClicked: {
                         if (connectButton.text == "Pair"){
                             bluetooth.pair(id)
                         }
                         else if (connectButton.text == "Connect"){
                             bluetooth.connect(id)
                         }
                         else if (connectButton.text == "Disconnect"){
                             bluetooth.disconnect(id)
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
          text: {
              if (bluetooth.power === true && pairedListView.count)
                    "LIST OF PAIRED DEVICES"
              else
                    ""
          }
      }
      ListView {
          id: pairedListView
          width: parent.width
          anchors.top: pairedlabel.bottom
          anchors.bottom: pairedlabel.bottom
          anchors.bottomMargin: (-120 * pairedListView.count)
          model: BluetoothPairedModel
          visible: bluetooth.power
          delegate: blueToothDevice
          clip: true
      }
      Image {
          anchors.top: pairedListView.bottom
          anchors.left: parent.left
          anchors.leftMargin: 80
          height: 5
          source: (bluetooth.power === true && pairedListView.count) ? '../images/HMI_Settings_DividingLine.svg':''
      }
      Text {
          id: detectedlabel
          width: parent.width
          anchors.top: pairedListView.bottom
          anchors.topMargin: pairedListView.count ? 80 : -80
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
          model: BluetoothDiscoveryModel
          visible: bluetooth.power
          delegate: blueToothDevice
          clip: true
      }
}
