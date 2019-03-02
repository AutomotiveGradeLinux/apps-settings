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
    id: audiolog

    property int currentsps: 0
    property int part1fontsize: 30
    property int part2fontsize: 30
    property int partheight: 50
    property int part1width: 250
    property int part2width: 600

    Item {
        implicitWidth: part1width
        implicitHeight: partheight
        Label {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            font.pixelSize: part1fontsize
            text: 'SPS  :  '
        }
    }

    TextField {
        id: textfield
        implicitWidth: part2width
        implicitHeight: partheight
        validator: IntValidator{bottom: 4000; top: 192000;}
        color: 'white'
        font.pixelSize: part2fontsize
        verticalAlignment: TextInput.AlignBottom
        Label {
            x: parent.width - width
            y: parent.height - height
            text: '(4000~192000)'
            color: 'gray'
            font.pixelSize: 20
        }
        onTextChanged: {
            if(text == '0') {
                text = ''
            }
            if(text.length > 0) {
                currentsps = text
            }
            else {
                currentsps = 0
            }
        }
        onFocusChanged: {
            root.updateKeyBoard()
            if(!focus && text < 4000) {
                text = 4000
            }
        }
        Component.onCompleted: {
            root.addTarget(textfield)
        }
    }
}
