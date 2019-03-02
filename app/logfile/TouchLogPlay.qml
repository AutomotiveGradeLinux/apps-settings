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
import TouchLogPlayImpl 1.0
import '..'

ColumnLayout {
    property int blankheight : 50
    property bool playing: false

    anchors.left: parent.left
    anchors.right: parent.right

    Item { height:blankheight }

    // Title
    RowLayout{
        anchors.left: parent.left
        anchors.right: parent.right
        Label { text: 'Touch Log files: ' ; color: '#59FF7F'}
    }

    Item { height:blankheight/3 }
    Image { source: '../images/HMI_Settings_DividingLine.svg' }
    Item { height:blankheight/3 }

    // List view
    ListView {
        id: touchloglist
        property int impheight: 0
        property int listitemheight : 50
        property int listmaxheight : 600

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        implicitHeight: 0
        clip: true
        model:touchlogplayimpl
        delegate: MouseArea {
            height: touchloglist.listitemheight
            width: ListView.view.width
            Label {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                visible: model.children > 0 ? true : false
                text: '' + model.children
                color: 'gray'
                font.pixelSize: 30
            }
            Image {
                source: '../images/HMI_Settings_DividingLine.svg'
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                visible: model.index > 0
            }
            Image {
                visible: touchloglist.currentIndex === model.index ? true : false
                anchors.fill: parent
                source:'./images/HMI_Settings_Button_Cancel.svg'
            }
            Label {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 5
                text: model.folder ? model.name : ' > ' + model.name
                color: model.folder ? 'gray' : (touchloglist.currentIndex === model.index ? 'orange' : 'white')
                font.pixelSize: 30
            }
            onClicked: {
                if(!model.folder) {
                    touchloglist.currentIndex = model.index
                }
            }
        }
        onCountChanged: {
            impheight = (count * listitemheight) > listmaxheight ? listmaxheight : (count * listitemheight)
            implicitHeight = impheight
        }

        Component.onCompleted: {
            currentIndex = -1
        }
        onCurrentIndexChanged: {
            model.setLogFileIndex(currentIndex)
        }
    }

    Item { height:blankheight/3 }
    Image { source: '../images/HMI_Settings_DividingLine.svg' }
    Item { height:blankheight/3 }

    Item { height:blankheight/3 }
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        Button {
            anchors.left: parent.left
            anchors.leftMargin: 100
            text: 'Refresh'
            highlighted: true
            onClicked: {
                touchloglist.currentIndex = -1
                touchlogplayimpl.refresh()
            }
        }
        Button {
            id:playstopbutton
            anchors.right: parent.right
            anchors.rightMargin: 100
            text: touchlogplayimpl.propTouchPlayFlag ? 'Stop' : 'Play'
            highlighted: true

            onClicked: {
                console.log("status:", playing);
                if(playing) {
                    touchlogplayimpl.touchPlay(false)
                }
                else {
                    touchlogplayimpl.setTouchProperty(touchloglist.currentIndex)
                    touchlogplayimpl.touchPlay(true)
                }
            }
        }
    }

    TouchLogPlayImpl {
        id: touchlogplayimpl

        onPropTouchPlayFlagChanged: {
            console.log("onPropTouchPlayFlagChanged:", touchlogplayimpl.propTouchPlayFlag);
            if(touchlogplayimpl.propTouchPlayFlag) {
                playstopbutton.text = "Stop"
            } else {
                playstopbutton.text = "Play"
            }
        }
    }

    onVisibleChanged: {
        if(visible) {
            touchlogplayimpl.refresh()
        }
        else {
            resetPosition()
        }
    }

    function adjustPosition(offset) {
        touchloglist.implicitHeight -= offset
        touchloglist.positionViewAtIndex(touchloglist.currentIndex, ListView.Beginning)
    }

    function resetPosition() {
        touchloglist.implicitHeight = touchloglist.impheight
    }
}
