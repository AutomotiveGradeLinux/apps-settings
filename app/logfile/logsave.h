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

#ifndef LOGSAVE_H
#define LOGSAVE_H

#include <QObject>
#include <QVariantList>

class LogSaveImpl : public QObject
{
    Q_OBJECT
public:
    explicit LogSaveImpl(QObject *parent = 0);
    ~LogSaveImpl();

public:
    Q_INVOKABLE bool saveStart(bool can, bool touch, bool video, bool audio);
    Q_INVOKABLE void saveStop();
    Q_INVOKABLE void setCANProperty();
    Q_INVOKABLE void setTouchProperty();
    Q_INVOKABLE void setVideoProperty(QStringList properties);
    Q_INVOKABLE void setAudioProperty(QString sps);
    Q_INVOKABLE QString getCurrentTrip();
    Q_INVOKABLE QString getCurrentSeg();
    Q_INVOKABLE bool createTripFolder();
    Q_INVOKABLE bool createLogFolders();
    Q_INVOKABLE QVariantList cameradevs() const;
    Q_INVOKABLE void enumerateCameras();
    Q_INVOKABLE int cameraCnt();

private:
    bool createSegFolder();

signals:
    void camraCntChanged(const QVariantList& camcnt);

private:
    static const QString TripPre;
    static const QString SegPre;

    static const QString FolderAudio;
    static const QString FolderVideo;
    static const QString FolderCAN;
    static const QString FolderTouch;
    static const QString FolderOther;

    static const QString RootFolder;

    static const std::string DumpUtilsExec;
    static const std::string AudioMixerExec;
    static const std::string AudioUtilsExec;
    static const std::string VideoUtilsExec;
    static const std::string TouchRecUtilsExec;

    QString currentSeg;
    QString currentTrip;
    QString rootPath;
//    std::map<QString, QString> videoDevice;
    std::map<QString, QString> logFolders;

    pid_t dumpUtils;
    pid_t audioMixer;
    pid_t audioUtils;
    pid_t videoUtils;
    pid_t touchRecUtils;

    QVariantList cameras;

    std::map<QString, QString> dumpUtilsArg;
    std::map<QString, QString> audioUtilsArg;
    std::map<QString, QString> videoUtilsArg;
    std::map<QString, QString> touchRecUtilsArg;
};

#endif // LOGSAVE_H
