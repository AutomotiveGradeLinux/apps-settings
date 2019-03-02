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
import QtQuick.Window 2.0
import QtQuick.Layouts 1.1

AbstractKeyboard {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.height / 10
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Repeater {
                model: ['1', '2', '3']
                delegate: Key {
                    text: model.modelData
                    Layout.preferredWidth: 2
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
            Key {
                image: '../images/Keyboard_Back.svg'
                Layout.preferredWidth: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: {
                    if (!clearSelctedText()) {
                        if (target && target.cursorPosition > 0)
                            target.remove(target.cursorPosition - 1, target.cursorPosition)
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Repeater {
                model: ['4', '5', '6']
                delegate: Key {
                    text: model.modelData
                    Layout.preferredWidth: 2
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
            Key {
                image: '../images/Keyboard_Arrow.svg'
                Layout.preferredWidth: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: {
                    root.hide()
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Repeater {
                model: ['7', '8', '9']
                delegate: Key {
                    text: model.modelData
                    Layout.preferredWidth: 2
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
            Key {
                text: 'Next'
                Layout.preferredWidth: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: {
                    root.next()
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Key {
                text: ' '
                Layout.preferredWidth: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                touchable: false
            }
            Key {
                text: '0'
                Layout.preferredWidth: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            Key {
                text: ' '
                Layout.preferredWidth: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                touchable: false
            }
            Key {
                text: 'Clear'
                Layout.preferredWidth: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: {
                    target.clear()
                }
            }
        }
    }
}
