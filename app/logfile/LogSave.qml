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
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.0
import LogSaveImpl 1.0
import '..'

ColumnLayout {
    property int blankheight : 50
    property bool saving : false

    anchors.left: parent.left
    anchors.right: parent.right

    Item { height:blankheight }
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        Label {
            text: 'CurPath  :  '
            color: 'white'
        }
        Label {
            id: logpath
            text: ''
            color: 'white'
            font.italic: true
            font.pixelSize: 20
        }
    }

    // Can log
    Item { height:blankheight/3 }
    Image {
        width: tabbar.width
        source: '../images/HMI_Settings_DividingLine.svg'
    }
    Item { height:blankheight/3 }
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        Label { text: 'CAN'; color: '#59FF7F' }
        Switch { id: canswitch;anchors.right: parent.right }
    }
//    Item { height:blankheight/3 }
    CANLog {}

    // Touch log
    Item { height:blankheight/3 }
    Image {
        width: tabbar.width
        source: '../images/HMI_Settings_DividingLine.svg'
    }
    Item { height:blankheight/3 }
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        Label { text: 'Touch'; color: '#59FF7F' }
        Switch { id: touchswitch;anchors.right: parent.right }
    }
//    Item { height:blankheight/3 }
    TouchLog {}

    // Video log
    Item { height:blankheight/3 }
    Image {
        width: tabbar.width
        source: '../images/HMI_Settings_DividingLine.svg'
    }
    Item { height:blankheight/3 }
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        Label { text: 'Video'; color: '#59FF7F' }
        Switch { id: videoswitch;anchors.right: parent.right }
    }
//    Item { height:blankheight/3 }
    VideoLog { id: videolog }

    //Audio log
    Item { height:blankheight/3 }
    Image {
        width: tabbar.width
        source: '../images/HMI_Settings_DividingLine.svg'
    }
    Item { height:blankheight/3 }
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        Label { text: 'Audio'; color: '#59FF7F' }
        Switch { id: audioswitch;anchors.right: parent.right }
    }
//    Item { height:blankheight/3 }
    AudioLog { id: audiolog }

    //Status bar
    Item { height:blankheight/3 }
    Image {
        width: tabbar.width
        source: '../images/HMI_Settings_DividingLine.svg'
    }
    Item { height:blankheight/3 }
    RowLayout {
        Label {
            text: 'Status: '
            color: '#59FF7F'
        }
        Label {
            id: recordstatus
            property int hour: 0
            property int minute: 0
            property int second: 0
            property string duration: ''
            text: saving ? ('Log Saving... '+ duration) : (hour > 0 || minute > 0 || second > 0) ? ('Duration: ' + duration) : 'Press SaveStart to save log file.'
            font.pixelSize: 30
            Timer {
                id: timer
                property double seconds: 0
                interval: 1000
                running: false
                repeat: true
                onTriggered: {
                    if(saving) {
                        seconds++
                        parent.hour = seconds/(60*60)
                        parent.minute = parent.hour > 0 ? seconds%(60*60)/60 : seconds/60
                        parent.second = seconds - parent.hour*(60*60) - parent.minute*60
                        parent.duration = (parent.hour > 0 ? (parent.hour + 'h ') : '')+(parent.minute > 0 ? (parent.minute + 'm ') : '')+(parent.second > 0 ? (parent.second + 's') : '')
                    }
                }
            }
        }
    }

    // Buttons
    Item { height:blankheight/3 }
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        Button {
            id: savestart
            anchors.horizontalCenter: parent.horizontalCenter
            text: saving ? 'SaveStop' : 'SaveStart'
            highlighted: true
            onClicked: {
                if(!saving && (canswitch.checked || touchswitch.checked || videoswitch.checked || audioswitch.checked)) {
                    if(logsaveimpl.createLogFolders()) {
                        logpath.text = logsaveimpl.getCurrentSeg()

                        if(canswitch.checked) {
                            logsaveimpl.setCANProperty()
                        }

                        if(touchswitch.checked) {
                            logsaveimpl.setTouchProperty()
                        }

                        if(videoswitch.checked) {
                            logsaveimpl.setVideoProperty(videolog.properties)
                        }

                        if(audioswitch.checked) {
                            logsaveimpl.setAudioProperty(audiolog.currentsps)
                        }

                        console.log("touchswitch.checked: " + touchswitch.checked)
                        if(logsaveimpl.saveStart(canswitch.checked, touchswitch.checked, videoswitch.checked, audioswitch.checked)) {
                            recordstatus.hour = recordstatus.minute = recordstatus.second = 0
                            recordstatus.duration = ''
                            timer.seconds = 0
                            timer.start()
                            saving = true
                        }
                    }
                }else if(saving) {
                    logsaveimpl.saveStop()
                    saving = false
                    timer.stop()
                }
            }
        }
    }
    LogSaveImpl {
        id: logsaveimpl
    }
    Component.onCompleted: {
        if(logsaveimpl.createTripFolder()) {
            logpath.text = trippath = logsaveimpl.getCurrentTrip()
        }
        else {
            logpath.text = ""
        }
    }

    onVisibleChanged: {
        if(!visible) {
            resetPosition()
        }
    }

    function adjustPosition(offset) {
        y -= offset
        var heights = 0
        for(var child in children) {
            heights += children[child].height
            if(heights <= offset) {
                children[child].opacity = 0
            }
            else {
                children[child].opacity = 0
                break
            }
        }
    }

    function resetPosition() {
        var children = logsave.children
        for(var child in children) {
            children[child].opacity = 1
        }
        logsave.y = 0
    }
}
