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

TabBar {
    id: root
    property int tabbtnwidth: 460
    property int tabbtnheight: 51
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 80
    background.opacity: 0
    Repeater {
        id: tabs
        model: ['Log Save', 'Log Play', 'Touch Log Play']
        delegate: TabButton {
            implicitWidth: tabbtnwidth
            implicitHeight: tabbtnheight
            contentItem: Text {
                text: model.modelData
                font.family: 'Roboto'
                font.pixelSize: 30
                opacity: enabled ? 1.0 : 0.3
                color: parent.down ? "#17a81a" : "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Image {
                anchors.fill: parent
                transform: parent.down ? opacity = 1.0 : opacity = 0.75
            }
        }
    }
    Component.onCompleted: {
        setBgImg()
    }

    onCurrentIndexChanged: {
        setBgImg()
    }

    function setBgImg() {
        for(var i = 0; i < tabs.count && i < root.count; i++) {
            if(i == root.currentIndex) {
                tabs.itemAt(i).background.source = './images/HMI_Settings_Button_Ok.svg';
            }
            else {
                tabs.itemAt(i).background.source = './images/HMI_Settings_Button_Cancel.svg';
            }
        }
    }
}
