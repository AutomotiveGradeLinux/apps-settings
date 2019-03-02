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
import LogPlayImpl 1.0
import '..'

ColumnLayout {
    property int blankheight : 50
    property bool playing: false

    property var timelist : ''
    property var stime : ['1970', '01', '01', '00', '00', '00']
    property var etime : ['1970', '01', '01', '00', '00', '00']
    property var portslist : ['None']

    anchors.left: parent.left
    anchors.right: parent.right

    Item { height:blankheight }

    RowLayout{
        anchors.left: parent.left
        anchors.right: parent.right
        Label { text: 'CAN Log files: ' ; color: '#59FF7F'}
        RowLayout{
            anchors.right: parent.right
            Label { text: 'Port : ' }
            ComboBox {
                id: ports
                implicitWidth: 220
                font.family: 'Roboto'
                font.pixelSize: 30
                model: portslist
                contentItem: Text {
                    text: ports.displayText
                    font: ports.font
                    color: ports.pressed ? "#17a81a" : "white"
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                indicator: Canvas {
                    id: canvas
                    x: ports.width - width - ports.rightPadding
                    y: ports.topPadding + (ports.availableHeight - height) / 2
                    width: 20
                    height: 12
                    contextType: "2d"

                    Connections {
                        target: ports
                        onPressedChanged: canvas.requestPaint()
                    }

                    onPaint: {
                        context.reset();
                        context.moveTo(0, 0);
                        context.lineTo(width, 0);
                        context.lineTo(width / 2, height);
                        context.closePath();
                        context.fillStyle = ports.pressed ? "#17a81a" : "white";
                        context.fill();
                    }
                }
                popup: Popup {
                    id: portspopup
                    y: ports.height - 1
                    implicitWidth: ports.width
                    implicitHeight: listview.contentHeight
                    padding: 0

                    contentItem: ListView {
                        id: listview
                        clip: true
                        model: portspopup.visible ? ports.delegateModel : null
                        currentIndex: ports.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }

                    background: Image {
                        source:'./images/HMI_Settings_Button_Cancel.svg'
                    }
                }
                delegate: ItemDelegate {
                    id: popupdelegate
                    width: ports.width
                    contentItem: Item {
                        implicitHeight: 30
                        Text {
                            text: modelData
                            color: popupdelegate.pressed || highlighted ? "#21be2b" : "white"
                            font: ports.font
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    highlighted: ports.highlightedIndex == index
                }

                background: Image {
                    source:'./images/HMI_Settings_Button_Cancel.svg'
                }
                onCurrentTextChanged: {
                    if(currentText != 'None') {
                        timelist = logplayimpl.getCanLogTime(currentText)
                    }
                }
                onModelChanged: {
                    if(currentText == '' || currentText == 'None') {
                        enabled = false
                    }
                    else {
                        enabled = true
                    }
                }
            }
        }
    }
    Item { height:blankheight/3 }
    Image { source: '../images/HMI_Settings_DividingLine.svg' }
    Item { height:blankheight/3 }
    ListView {
        id: loglist
        property int impheight: 0
        property int listitemheight : 50
        property int listmaxheight : 600

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        implicitHeight: 0
        clip: true
        model:logplayimpl
        delegate: MouseArea {
            height: loglist.listitemheight
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
                visible: loglist.currentIndex === model.index ? true : false
                anchors.fill: parent
                source:'./images/HMI_Settings_Button_Cancel.svg'
            }
            Label {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 5
                text: model.folder ? model.name : ' > ' + model.name
                color: model.folder ? 'gray' : (loglist.currentIndex === model.index ? 'orange' : 'white')
                font.pixelSize: 30
            }
            onClicked: {
                if(!model.folder) {
                    loglist.currentIndex = model.index
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
            portslist = model.getPortsList()
            if(portslist.length == 0) {
                portslist = ['None']
            }
            timelist = model.getCanLogTime(ports.currentText)
        }
    }
    Item { height:blankheight/3 }
    Image { source: '../images/HMI_Settings_DividingLine.svg' }
    Item { height:blankheight/3 }
    Repeater {
        id: logtime
        model: ['Start Time : ', 'End Time : ']
        delegate: RowLayout {
            property var curidx: model.index
            Item {
                implicitHeight: 50
                implicitWidth: 250
                Label {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: model.modelData
                }
            }
            Repeater{
                id: datetime
                property list<IntValidator> range: [
                    IntValidator{bottom: 0; top: 23;},
                    IntValidator{bottom: 0; top: 59;},
                    IntValidator{bottom: 0; top: 59;}
                ]
                model: 6
                RowLayout {
                    implicitHeight: 50
                    implicitWidth: 120
                    Label {
                        anchors.bottom: parent.bottom
                        visible: model.index > 0 ? true : false
                        text: model.index === 3 ? '   ' : model.index > 3 ? ':' : '/'
                        color: model.index < 3 ? 'gray' : 'white'
                        font.pixelSize: 30
                    }
                    TextField {
                        implicitWidth: model.index > 0 ? 60 : 90
                        width: model.index > 0 ? 60 : 90
                        text: (curidx*datetime.count + model.index) >= timelist.length ? '-' : timelist[(curidx*datetime.count + model.index)]
                        color: model.index > 2 ? 'white' : 'gray'
                        enabled: false
                        font.pixelSize: 30
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignBottom
                        onTextChanged: {
                            if(model.index > 2 && text !== '/') {
                                enabled = true
                                if(text.length > 2) {
                                    text = text.substring(text.length-2, text.length)
                                }
                            }
                            else {
                                enabled = false
                            }
                            if(curidx == 0 ) {
                                if(model.index < stime.length) {
                                    stime[model.index] = text;
                                }
                            }
                            else {
                                if(model.index < stime.length) {
                                    etime[model.index] = text;
                                }
                            }
                        }
                        onFocusChanged: {
                            root.updateKeyBoard()
                            if(!focus) {
                                if(text.length === 0) {
                                    text = '00'
                                }
                                else if(text.length === 1 && text !== '/') {
                                    text = '0' + text
                                }
                            }
                        }
                    }
                }
                Component.onCompleted: {
                    for(var i = 3, j = 0; i < count && j < range.length; i++, j++) {
                        itemAt(i).children[1].validator = range[j]
                        root.addTarget(itemAt(i).children[1])
                    }
                }
            }
            Label {
                property int timeindex: 3+curidx*datetime.count
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: (timelist.length <= timeindex+2) ? '(-:-:-)' :
                                                         '('+timelist[timeindex]+':'+timelist[timeindex+1]+':'+timelist[timeindex+2]+')'
                color: 'gray'
                font.pixelSize: 20
            }
        }
    }
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
                loglist.currentIndex = -1
                logplayimpl.refresh()
            }
        }
        Button {
            anchors.right: parent.right
            anchors.rightMargin: 100
            text: playing ? 'Stop' : 'Play'
            highlighted: true
            onClicked: {
                if(playing) {
                    playing = false
                    logplayimpl.CANPlay(false)
                }
                else {
                    if(logplayimpl.checkTime(ports.currentText, stime, etime))
                    {
                        logplayimpl.setCANProperty(loglist.currentIndex, ports.currentText, stime, etime)
                        if(logplayimpl.CANPlay(true))
                            playing = true
                    }
                }
            }
        }
    }

    LogPlayImpl { id: logplayimpl }

    onVisibleChanged: {
        if(visible) {
            logplayimpl.refresh()
        }
        else {
            resetPosition()
        }
    }

    function adjustPosition(offset) {
        loglist.implicitHeight -= offset
        loglist.positionViewAtIndex(loglist.currentIndex, ListView.Beginning)
    }

    function resetPosition() {
        loglist.implicitHeight = loglist.impheight
    }
}
