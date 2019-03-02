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
import '..'
import './keyboard'

SettingPage {
    id: root
    icon: '/logfile/images/HMI_Settings_LogFile.svg'
    title: 'LogFile'
    property string trippath: ''
    property string rootpath: ''
    property var targets: new Array()

    Bar {
        id: tabbar
        onCurrentIndexChanged: {
            keyboard.visible = false
        }
    }
    StackLayout {
        id: pages
        anchors.left: tabbar.left
        anchors.right: tabbar.right
        anchors.top: tabbar.bottom
        currentIndex: tabbar.currentIndex
        LogSave { id: logsave }
        LogPlay { id: logplay }
        TouchLogPlay { id: touchlogplay }
    }

    Keyboard {
        id: keyboard
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        active: numbers
        onVisibleChanged: {
            var children = pages.children
            for(var child in children) {
                if(children[child].visible) {
                    children[child].resetPosition()
                    break;
                }
            }
        }
        Numbers {
            id: numbers
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: parent.height / 2
            anchors.rightMargin: parent.height / 2
            target: parent.target
            onHide: {
                keyboard.visible = false
                target.focus = false
            }
            onNext: {
                var nexttarget
                for(var i = 0; i < targets.length; i++) {
                    if(targets[i] === target) {
                        for(var j = i, k = 0; k < targets.length; k++) {
                            if(j === targets.length-1) {
                                j = 0;
                            }
                            else {
                                j++;
                            }
                            if(targets[j].visible) {
                                target.focus = false
                                nexttarget = targets[j]
                                nexttarget.focus = true
                                break;
                            }
                        }
                        break;
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if(!visible) {
            keyboard.visible = false
        }
    }

    function updateKeyBoard() {
        var textfield = 0
        for(var i = 0; i < targets.length; i++) {
            if(targets[i].focus) {
                textfield = targets[i]
            }
        }

        if(textfield === 0) {
            keyboard.visible = false
            return
        }
        else {
            keyboard.target = textfield
            keyboard.visible = true
        }

        var implicity = 0.0
        for(var itext = textfield; itext !== pages; itext = itext.parent) {
            implicity += itext.y
        }
        implicity += itext.y

        var keyboardy = implicity + textfield.height
        if(keyboard.y < keyboardy) {
            var children = pages.children
            for(var child in children) {
                if(children[child].visible) {
                    children[child].adjustPosition(keyboardy - keyboard.y)
                    break;
                }
            }
        }
    }

    function addTarget(target) {
        targets.push(target)
    }
}
