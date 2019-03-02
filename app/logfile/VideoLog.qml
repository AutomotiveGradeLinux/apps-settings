/*
 * Copyright (c) 2017 TOYOTA MOTOR CORPORATION
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

RowLayout {
    id: videolog

    property var properties: ['', 0, 0,0]

    property int part1width: 250
    property int part2width: 600
    property int partheight: 50
    property int part1fontsize: 30
    property int part2fontsize: 30
    property var cameradevs: []

    ColumnLayout{
        Repeater {
            model: ['Zone  :  ', 'FPS  :  ', 'Width  :  ', 'Height  :  ']
            delegate: Item {
                implicitWidth: part1width
                implicitHeight: partheight
                Label {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    font.pixelSize: part1fontsize
                    text: model.modelData
                }
            }
        }
    }
    ColumnLayout{
//        RowLayout{
//            implicitWidth: part2width
//            implicitHeight: partheight
//            ButtonGroup {
//                id: zonegroup
//            }
//            Repeater {
//                id: zones
//                model: ['None', 'Front', 'Rear', 'Left', 'Right']
//                delegate: CheckBox {
//                    text: model.modelData
//                    font.family: 'Roboto'
//                    font.pixelSize: part2fontsize
//                    ButtonGroup.group: zonegroup
//                    contentItem: Text {
//                        text: parent.text
//                        font: parent.font
//                        color:'white'
//                        horizontalAlignment: Text.AlignHCenter
//                        verticalAlignment: Text.AlignVCenter
//                        leftPadding: parent.indicator.width + parent.spacing
//                    }
//                    onCheckedChanged: {
//                        if(checked) {
//                            properties[0] = text
//                        }
//                    }
//                }
//                Component.onCompleted: {
//                    zones.itemAt(0).checked = true
//                }
//            }
//        }

        ComboBox {
            id: camerainfo
            implicitWidth: part2width
            font.pixelSize: 25
            model: cameradevs
            contentItem: Text {
                text: camerainfo.displayText
                font: camerainfo.font
                color: camerainfo.pressed ? "#17a81a" : "white"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            indicator: Canvas {
                id: canvas
                x: camerainfo.width - width - camerainfo.rightPadding
                y: camerainfo.topPadding + (camerainfo.availableHeight - height) / 2
                width: 20
                height: 12
                contextType: "2d"

                Connections {
                    target: camerainfo
                    onPressedChanged: {
                        canvas.requestPaint()
                        properties[0] = camerainfo.displayText
                        console.log("onPressedChanged", properties[0])
                    }
                }

                onPaint: {
                    context.reset();
                    context.moveTo(0, 0);
                    context.lineTo(width, 0);
                    context.lineTo(width / 2, height);
                    context.closePath();
                    context.fillStyle = camerainfo.pressed ? "#17a81a" : "white";
                    context.fill();
                }
            }
            popup: Popup {
                id: popup
                y: camerainfo.height - 1
                implicitWidth: camerainfo.width
                implicitHeight: listview.count > 6 ? (listview.contentHeight/3.3) : listview.contentHeight
                padding: 0

                contentItem: ListView {
                    id: listview
                    clip: true
                    model: camerainfo.visible ? camerainfo.delegateModel : null
                    currentIndex: camerainfo.highlightedIndex
                    ScrollIndicator.vertical: ScrollIndicator { }
                }

                background: Image { source: "images/camerainfo_bg.svg" }
            }
            delegate: ItemDelegate {
                id: popupdelegate
                width: camerainfo.width
                contentItem: Item {
                    implicitHeight: 30
                    Text {
                        text: modelData
                        color: popupdelegate.pressed ||  highlighted ? "#21be2b" : "white"
                        font: camerainfo.font
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                highlighted: camerainfo.highlightedIndex == index
            }

            background: Image { source: "images/camerainfo_bg.svg" }

            onCurrentTextChanged: {
                properties[0] = camerainfo.currentText
                console.log("onCurrentTextChanged", properties[0])
            }
        }

        Repeater {
            id: textfields
            property list<IntValidator> range: [
                IntValidator{bottom: 0; top: 100;},
                IntValidator{bottom: 0; top: 2000;},
                IntValidator{bottom: 0; top: 2000;}
            ]
            model: ['(0~100)', '(0~2000)', '(0~2000)']
            delegate: TextField {
                implicitWidth: part2width
                implicitHeight: partheight
                color: 'white'
                font.pixelSize: part2fontsize
                verticalAlignment: TextInput.AlignBottom
                Label {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: model.modelData
                    color: 'gray'
                    font.pixelSize: 20
                }
                onTextChanged: {
                    if(text == '0') {
                        text = ''
                    }
                    if(model.index + 1 < properties.length) {
                        properties[model.index + 1] = text
                    }
                }
                onFocusChanged: {
                    root.updateKeyBoard()
                }
            }
            Component.onCompleted: {
                for(var i = 0; i < textfields.count && i < range.length; i++) {
                    textfields.itemAt(i).validator = range[i]
                    root.addTarget(textfields.itemAt(i))
                }
            }
        }
    }

    Component.onCompleted: {
        logsaveimpl.enumerateCameras();
        cameradevs = logsaveimpl.cameradevs();
        properties[0] = cameradevs[0]
        console.log(properties[0]);
    }
}
