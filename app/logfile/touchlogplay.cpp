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

#include "touchlogplay.h"
#include <QDir>
#include <QDirIterator>
#include <QDateTime>
#include <QTextStream>
#include <sys/wait.h>
#include <unistd.h>
#include <signal.h>
#include <QDebug>

const std::string TouchLogPlayImpl::touchPlayUtilsExec = "/usr/bin/tsplayer";
TouchLogPlayImpl *TouchLogPlayImpl::pointer = NULL;
bool TouchLogPlayImpl::touchPlayFlag = false;
void (*TouchLogPlayImpl::oldHandler)(int) = NULL;

TouchLogPlayImpl::TouchLogPlayImpl(QObject *parent) : QAbstractItemModel(parent)
{
    roles[nameRole] = "name";
    roles[folderRole] = "folder";
    roles[childrenRole] = "children";
    roles[pathRole] = "path";

    touchPlayUtils = -1;
    pointer = this;
}

TouchLogPlayImpl::~TouchLogPlayImpl()
{
    touchPlay(false);
}

int TouchLogPlayImpl::rowCount(const QModelIndex &parent) const
{
    (void)parent;
    return datas.size();
}

int TouchLogPlayImpl::columnCount(const QModelIndex &parent) const
{
    (void)parent;
    return 1;
}

QModelIndex TouchLogPlayImpl::index(int row, int column, const QModelIndex &parent) const
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

QVariant TouchLogPlayImpl::data(const QModelIndex &index, int role) const
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

QModelIndex TouchLogPlayImpl::parent(const QModelIndex &child) const
{
    (void)child;
    return QModelIndex();
}

QHash<int,QByteArray> TouchLogPlayImpl::roleNames() const
{
    return roles;
}

void TouchLogPlayImpl::refresh()
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

            QDirIterator it(list.at(i).filePath(), QStringList() << "*.touch", QDir::Files | QDir::NoSymLinks, QDirIterator::Subdirectories);
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

void TouchLogPlayImpl::setLogFileIndex(int index)
{
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
                }
            }
            file.close();
        }
    }
}

bool TouchLogPlayImpl::touchPlay(bool play)
{
    qDebug() << "touchPlayFlag:" << touchPlayFlag;
    if(play)
    {
        oldHandler = signal(SIGCHLD, finalizeChild);
        if(oldHandler == SIG_ERR)
        {
            qDebug("signal error.");
            return false;
        }

        touchPlayUtils = fork();
        switch(touchPlayUtils)
        {
        case 0:
            execl(touchPlayUtilsExec.c_str(), basename(touchPlayUtilsExec.c_str()),
                  "-d", "1",
                  "-f", touchplayUtilsArg["-f"].toStdString().c_str(),
                  "-e", "1",
                  (char*)NULL);
            break;
        default:
            touchPlayFlag = true;
            emit propTouchPlayFlagChanged();
            qDebug() << "default:";
            break;
        }
    }
    else
    {
        if(touchPlayFlag)
        {
            if((touchPlayUtils > 0) && (kill(touchPlayUtils, SIGUSR1) == 0))
            {
                waitpid(touchPlayUtils, NULL, 0);
            }
        }
    }

    return true;
}

void TouchLogPlayImpl::setTouchProperty(int index)
{
    if(index > 0 && index < datas.size())
    {
        touchplayUtilsArg["-f"] = datas[index][pathRole].toString();
    }
}

bool TouchLogPlayImpl::propTouchPlayFlag() const
{
    return touchPlayFlag;
}

void TouchLogPlayImpl::propTouchPlayFlagChangedDelegate()
{
    emit propTouchPlayFlagChanged();
}

void TouchLogPlayImpl::finalizeChild(int sig)
{
    if(sig == SIGCHLD)
    {
        qDebug("finalizeChild start.");
        waitpid(-1, NULL, 0);
        touchPlayFlag = false;
        emit pointer->propTouchPlayFlagChangedDelegate();
        qDebug("finalizeChild end.");
    }

    if(signal(SIGCHLD, oldHandler) == SIG_ERR)
    {
        qDebug("signal error.");
    }
}
