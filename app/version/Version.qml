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
import QtQuick.Window 2.2
import AGL.Demo.Controls 1.0
import '..'

SettingPage {
    id: root
    icon: '/version/images/icon.svg'
    title: 'Version Info'

    ColumnLayout {
        id: container
        anchors.fill: parent
        anchors.margins: 100
        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 500
            text: 'Automotive\nGrade Linux'
            font.pixelSize: 128
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
            clip: true
            Image {
                anchors.centerIn: parent
                source: './images/agl_slide_0.png'
                z: -1
                opacity: 0.5
            }
        }

        GridLayout {
            columns: 2
            rowSpacing: 20
            columnSpacing: 20
            Label {
                text: 'AGL:'
                font.pixelSize: 48
            }
            Label {
                text: '3.0 (Charming Chinook)'
                font.pixelSize: 48
                Layout.fillWidth: true
            }
            Label {
                text: 'Kernel:'
                font.pixelSize: 48
            }
            Label {
                text: kernel
                font.pixelSize: 48
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
