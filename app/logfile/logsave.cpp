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

#include "logsave.h"

#include <QDateTime>
#include <QDir>
#include <sys/wait.h>
#include <unistd.h>

#include <fcntl.h>
#include <sys/ioctl.h>
#include <opencv2/imgproc.hpp>
#include <linux/videodev2.h>

const QString LogSaveImpl::TripPre = "Trip_";
const QString LogSaveImpl::SegPre = "Seg_";

const QString LogSaveImpl::FolderAudio = "AUDIO";
const QString LogSaveImpl::FolderVideo = "VIDEO";
const QString LogSaveImpl::FolderCAN = "CAN";
const QString LogSaveImpl::FolderTouch = "TOUCH";
const QString LogSaveImpl::FolderOther = "OTHER";

const QString LogSaveImpl::RootFolder = "LogDataFile";

const std::string LogSaveImpl::DumpUtilsExec = "/usr/bin/candump";
const std::string LogSaveImpl::AudioMixerExec = "/usr/bin/amixer";
const std::string LogSaveImpl::AudioUtilsExec = "/usr/bin/arecord";
const std::string LogSaveImpl::VideoUtilsExec = "/usr/bin/videoutils";
const std::string LogSaveImpl::TouchRecUtilsExec = "/usr/bin/tsrecorder";

LogSaveImpl::LogSaveImpl(QObject *parent):QObject(parent)
{
//    videoDevice["None"] = "10";
//    videoDevice["Front"] = "1";
//    videoDevice["Right"] = "2";
//    videoDevice["Left"] = "3";
//    videoDevice["Rear"] = "4";

    logFolders[FolderAudio] = "";
    logFolders[FolderVideo] = "";
    logFolders[FolderCAN] = "";
    logFolders[FolderOther] = "";
    logFolders[FolderTouch] = "";

    rootPath = QDir::homePath() + "/" + RootFolder;
    QDir rootdir(rootPath);
    if(!rootdir.exists())
    {
        if(!rootdir.mkdir(rootPath))
        {
            rootPath = "/tmp";
        }
    }

    dumpUtils = -1;
    audioMixer = -1;
    audioUtils = -1;
    videoUtils = -1;
    touchRecUtils = -1;
}

LogSaveImpl::~LogSaveImpl()
{
    saveStop();
}

void LogSaveImpl::setVideoProperty(QStringList properties)
{
    if(properties.length() < 4)
    {
        return;
    }

//    videoUtilsArg["-d"] = videoDevice[properties[0]];
    videoUtilsArg["-d"] = properties[0].remove("/dev/video");
    videoUtilsArg["-r"] = (properties[1] != "0" ? properties[1] : "30");
    videoUtilsArg["-w"] = (properties[2] != "0" ? properties[2] : "640");
    videoUtilsArg["-h"] = (properties[3] != "0" ? properties[3] : "480");
    videoUtilsArg["-f"] = logFolders[FolderVideo] + QDateTime::currentDateTime().toString("yyyy_MM_dd_hh_mm_ss") + ".avi";
}

void LogSaveImpl::setCANProperty()
{
    dumpUtilsArg["-L"] = logFolders[FolderCAN] + QDateTime::currentDateTime().toString("yyyy_MM_dd_hh_mm_ss") + ".log";
}

void LogSaveImpl::setTouchProperty()
{
    touchRecUtilsArg["-f"] = logFolders[FolderTouch] + QDateTime::currentDateTime().toString("yyyy_MM_dd_hh_mm_ss") + ".touch";
}

void LogSaveImpl::setAudioProperty(QString sps)
{
    audioUtilsArg["-r"] = (sps != "0" ? sps : "44100");
    audioUtilsArg["-f"] = logFolders[FolderAudio] + QDateTime::currentDateTime().toString("yyyy_MM_dd_hh_mm_ss") + ".wav";
}

bool LogSaveImpl::saveStart(bool can, bool touch, bool video, bool audio)
{
    qDebug("touch:%d", touch);
    if(video)
    {
        qDebug("-d:%s", videoUtilsArg["-d"].toStdString().c_str());
        videoUtils = fork();
        switch(videoUtils)
        {
        case 0:
            execl(VideoUtilsExec.c_str(), basename(VideoUtilsExec.c_str()),
                  "-d", videoUtilsArg["-d"].toStdString().c_str(),
                  "-w", videoUtilsArg["-w"].toStdString().c_str(),
                  "-h", videoUtilsArg["-h"].toStdString().c_str(),
                  "-r", videoUtilsArg["-r"].toStdString().c_str(),
                  "-f", videoUtilsArg["-f"].toStdString().c_str(),
                  "-c", "MP42",
                  (char *)NULL);
            break;
        default:
            break;
        }
    }

    if(can)
    {
        int fd;
        dumpUtils = fork();
        switch(dumpUtils)
        {
        case 0:
            fd = open(dumpUtilsArg["-L"].toStdString().c_str(), O_CREAT | O_WRONLY, 0666);
            dup2(fd, 1);
            close(fd);     /* fd は以後不要なので close() */
            execl(DumpUtilsExec.c_str(), basename(DumpUtilsExec.c_str()), "vcan0", "-L", (char *)NULL);
            break;
        default:
            break;
        }
    }

    if(touch)
    {
        touchRecUtils = fork();
        qDebug("touchRecUtils:%d", touchRecUtils);
        switch(touchRecUtils)
        {
        case 0:
            qDebug("TouchRecUtilsExec:%s", touchRecUtilsArg["-f"].toStdString().c_str());
            execl(TouchRecUtilsExec.c_str(), basename(TouchRecUtilsExec.c_str()), "-f", touchRecUtilsArg["-f"].toStdString().c_str(), (char *)NULL);
            break;
        default:
            break;
        }
    }

    if(audio)
    {
        // Set volume
        audioMixer = fork();
        switch(audioMixer)
        {
        case 0:
            execl(AudioMixerExec.c_str(), basename(AudioMixerExec.c_str()), "-D", "hw:ak4613", "cset", "name='DVC In Capture Volume'", "100%", (char*)NULL);
            break;
        default:
            break;
        }
        if(audioMixer > 0)
        {
            waitpid(audioMixer, NULL, 0);
        }

        // Set mute off
        audioMixer = fork();
        switch(audioMixer)
        {
        case 0:
            execl(AudioMixerExec.c_str(), basename(AudioMixerExec.c_str()), "-D", "hw:ak4613", "cset", "name='DVC In Mute Switch'", "off", (char*)NULL);
            break;
        default:
            break;
        }
        if(audioMixer > 0)
        {
            waitpid(audioMixer, NULL, 0);
        }

        // Start record
        audioUtils = fork();
        switch(audioUtils)
        {
        case 0:
            execl(AudioUtilsExec.c_str(), basename(AudioUtilsExec.c_str()), "-c", "2", "-f", "S24_LE", "-r", audioUtilsArg["-r"].toStdString().c_str(), "-t", "wav", "-D", "hw:ak4613", audioUtilsArg["-f"].toStdString().c_str(), (char*)NULL);
            break;
        default:
            break;
        }
    }
    return true;
}

void LogSaveImpl::saveStop()
{
    if((videoUtils > 0) && (kill(videoUtils, SIGUSR1) == 0))
    {
        waitpid(videoUtils, NULL, 0);
    }

    if((dumpUtils > 0) && (kill(dumpUtils, SIGUSR1) == 0))
    {
        waitpid(dumpUtils, NULL, 0);
    }

    if((audioUtils > 0) && (kill(audioUtils, SIGKILL) == 0))
    {
        waitpid(audioUtils, NULL, 0);
    }

    if((touchRecUtils > 0) && (kill(touchRecUtils, SIGKILL) == 0))
    {
        waitpid(touchRecUtils, NULL, 0);
    }
}

bool LogSaveImpl::createLogFolders()
{
    bool result = false;

    if(createSegFolder())
    {
        QString path;
        QDir dir;

        result = true;

        for(std::map<QString,QString>::iterator it = logFolders.begin(); it != logFolders.end(); it++)
        {
            path = currentSeg + "/" + it->first;
            if(!dir.exists(path) && !dir.mkdir(path))
            {
                it->second = "";
            }
            else
            {
                it->second = path + "/";
            }
        }
    }
    return result;
}

bool LogSaveImpl::createTripFolder()
{
    currentTrip = "";
    if(!rootPath.isEmpty())
    {
        QDir tripdir;

        currentTrip = rootPath + "/" + TripPre + QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss");

        if(!tripdir.exists(currentTrip) && !tripdir.mkdir(currentTrip))
        {
            currentTrip = "";
        }
    }

    if(currentTrip.isEmpty())
    {
        return false;
    }
    else
    {
        return true;
    }
}

bool LogSaveImpl::createSegFolder()
{
    currentSeg = "";

    if(!currentTrip.isEmpty())
    {
        QDir segdir;

        currentSeg = currentTrip + "/" + SegPre + QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss");

        if(!segdir.exists(currentSeg) && !segdir.mkdir(currentSeg))
        {
            currentSeg = "";
        }
    }

    if(currentSeg.isEmpty())
    {
        return false;
    }
    else
    {
        return true;
    }
}

void LogSaveImpl::enumerateCameras() {
    int maxID = 11;
    for (int idx = 0; idx <maxID; idx++){
        std::stringstream  no;
        no << "/dev/video" << idx;
        int fd = open(no.str().c_str(), O_RDWR);
        if (fd != -1){
            struct v4l2_capability cap;

            if (ioctl(fd,VIDIOC_QUERYCAP,&cap) != -1){
                if ((cap.capabilities & (V4L2_CAP_VIDEO_CAPTURE | V4L2_CAP_STREAMING)) == (V4L2_CAP_VIDEO_CAPTURE | V4L2_CAP_STREAMING)){
                    qDebug("cap.driver %s, cap.card %s, cap.bus_info %s", (char*)(cap.driver), (char*)(cap.card), (char*)(cap.bus_info));
                    if(strcmp((char*)cap.driver, "uvcvideo") == 0)
                    {
                        cameras.push_back(no.str().c_str());  // vector of all available cameras
                    }
                }
            }
            close(fd);
        }
    }
}

QVariantList LogSaveImpl::cameradevs() const{
    return cameras;
}

int LogSaveImpl::cameraCnt() {
    return cameras.length();
}

QString LogSaveImpl::getCurrentTrip()
{
    return currentTrip;
}

QString LogSaveImpl::getCurrentSeg()
{
    return currentSeg;
}
