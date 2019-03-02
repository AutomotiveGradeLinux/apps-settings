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

#include "logplay.h"
#include <QDir>
#include <QDirIterator>
#include <QDateTime>
#include <QTextStream>
#include <sys/wait.h>
#include <unistd.h>

const std::string LogPlayImpl::PlayUtilsExec = "/usr/bin/canplayer";

LogPlayImpl::LogPlayImpl(QObject *parent) : QAbstractItemModel(parent)
{
    roles[nameRole] = "name";
    roles[folderRole] = "folder";
    roles[childrenRole] = "children";
    roles[pathRole] = "path";

    playUtils = -1;
}

LogPlayImpl::~LogPlayImpl()
{
    CANPlay(false);
}

int LogPlayImpl::rowCount(const QModelIndex &parent) const
{
    (void)parent;
    return datas.size();
}

int LogPlayImpl::columnCount(const QModelIndex &parent) const
{
    (void)parent;
    return 1;
}

QModelIndex LogPlayImpl::index(int row, int column, const QModelIndex &parent) const
{
    (void)parent;
    if((row >= 0) && (row < datas.size()))
    {
        return createIndex(row,column);
    }
    else
    {
        return QModelIndex();
    }
}

QVariant LogPlayImpl::data(const QModelIndex &index, int role) const
{
    if(index.isValid() && index.row()<datas.size())
    {
        return datas[index.row()][role];
    }
    else
    {
        QHash<int,QVariant> data;
        data[nameRole] = "";
        data[folderRole] = true;
        data[childrenRole] = 0;
        return data[role];
    }
}

QModelIndex LogPlayImpl::parent(const QModelIndex &child) const
{
    (void)child;
    return QModelIndex();
}

QHash<int,QByteArray> LogPlayImpl::roleNames() const
{
    return roles;
}

void LogPlayImpl::refresh()
{
    QDir dir(QDir::homePath() + "/" + "LogDataFile");

    if(dir.exists())
    {
        beginResetModel();
        dir.setFilter(QDir::Dirs | QDir::NoDotAndDotDot);
        dir.setSorting(QDir::Name);

        QFileInfoList list = dir.entryInfoList();
        datas.clear();

        for(int i = 0; i < list.size(); i++)
        {
            QHash<int,QVariant> parent;
            QStringList children;

            parent[nameRole] = list.at(i).fileName();
            parent[folderRole] = true;
            parent[pathRole] = list.at(i).absoluteFilePath();

            children.clear();

            QDirIterator it(list.at(i).filePath(), QStringList() << "*.log", QDir::Files | QDir::NoSymLinks, QDirIterator::Subdirectories);
            while(it.hasNext())
            {
                children << it.next();
            }

            parent[childrenRole] = children.count();
            datas.append(parent);

            if(children.count() > 0)
            {
                children.sort();

                for(int j = 0; j < children.count(); j++)
                {
                    QHash<int,QVariant> child;

                    child[nameRole] = children.at(j).section("/", -1);
                    child[folderRole] = false;
                    child[childrenRole] = 0;
                    child[pathRole] = children.at(j);

                    datas.append(child);
                }
            }
        }
        endResetModel();
    }
}

void LogPlayImpl::setLogFileIndex(int index)
{
    startTime.clear();
    endTime.clear();
    portsList.clear();

    if(index > 0 && index < datas.size())
    {
        QFile file(datas[index][pathRole].toString());

        if(file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text))
        {
            QTextStream filetxt(&file);
            QString line = "";
            QString port = "";
            QDateTime datetime;

            while(!filetxt.atEnd())
            {
                line = filetxt.readLine();
                if(!line.isEmpty())
                {
                    port = line.section(" ", 1, 1, QString::SectionSkipEmpty);
                    if(port.isEmpty())
                    {
                        port = line.section("\t", 1, 1, QString::SectionSkipEmpty);
                    }
                    datetime = QDateTime::fromTime_t(line.mid(line.indexOf("(")+1, line.indexOf(".")-line.indexOf("(")-1).toUInt());
                    if(!portsList.contains(port))
                    {
                        portsList << port;
                        startTime[port] << datetime.toString("yyyy") << datetime.toString("MM") << datetime.toString("dd")
                                        << datetime.toString("hh") << datetime.toString("mm") << datetime.toString("ss");
                    }
                    if(endTime.find(port) != endTime.end())
                    {
                        endTime[port].clear();
                    }
                    endTime[port] << datetime.toString("yyyy") << datetime.toString("MM") << datetime.toString("dd")
                                  << datetime.toString("hh") << datetime.toString("mm") << datetime.toString("ss");
                }
            }
            file.close();
        }
    }
}

QStringList LogPlayImpl::getCanLogTime(QString port)
{
    if(startTime.find(port) != startTime.end() && endTime.find(port) != endTime.end())
    {
        return startTime[port] + endTime[port];
    }
    else
    {
        return QStringList();
    }
}

QStringList LogPlayImpl::getPortsList()
{
    return portsList;
}

bool LogPlayImpl::CANPlay(bool play)
{
    if(play)
    {
        playUtils = fork();
        switch(playUtils)
        {
        case 0:
            execl(PlayUtilsExec.c_str(), basename(PlayUtilsExec.c_str()),
                  playUtilsArg["-p"].toStdString().c_str(),
                  "-I", playUtilsArg["-I"].toStdString().c_str(),
                  "-l", "i",
                  (char*)NULL);
            break;
        default:
            break;
        }
    }
    else
    {
        if((playUtils > 0) && (kill(playUtils, SIGUSR1) == 0))
        {
            waitpid(playUtils, NULL, 0);
        }
    }

    return true;
}

void LogPlayImpl::setCANProperty(int index, QString port, QString stime, QString etime)
{
    if(index > 0 && index < datas.size())
    {
        playUtilsArg["-p"] = "vcan0="+port;
        playUtilsArg["-I"] = datas[index][pathRole].toString();
    }
}

bool LogPlayImpl::checkTime(QString port, QString stime, QString etime)
{
    QString maxtime = "";
    QString mintime = "";

    if(startTime.find(port) == startTime.end() || endTime.find(port) == endTime.end())
    {
        return false;
    }

    for(int idx = 0; idx < startTime[port].length() && idx < endTime[port].length(); idx++)
    {
        mintime += startTime[port].at(idx) + (idx == startTime[port].length() - 1 ? "" : ",");
        maxtime += endTime[port].at(idx) + (idx == endTime[port].length() - 1 ? "" : ",");
    }

    if((stime < mintime) || (stime > maxtime) || (etime < mintime) || (etime > maxtime) || (stime > etime))
    {
        return false;
    }
    else
    {
        return true;
    }
}

QString LogPlayImpl::convertTimeFormat(QString time)
{
    QStringList sep;
    QString convertstr = "";

    sep << "-" << "-" << "." << ":" << ":";

    //2016-02-08.09:41:59
    for(int idx = 0; idx <= time.count(","); idx++)
    {
        convertstr += time.section(',' , idx, idx) + (idx < sep.length() ? sep.at(idx) : "");
    }

    return convertstr;
}
