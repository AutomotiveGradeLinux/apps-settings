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

#ifndef LOGPLAYIMPPL_H
#define LOGPLAYIMPPL_H

#include <QAbstractItemModel>

class LogPlayImpl: public QAbstractItemModel
{
    Q_OBJECT
public:
    explicit LogPlayImpl(QObject *parent = 0);
    ~LogPlayImpl();

    enum LogPlayImplRoles{
        nameRole=Qt::UserRole+1,
        folderRole,
        childrenRole,
        pathRole
    };

    int rowCount(const QModelIndex &parent=QModelIndex()) const Q_DECL_OVERRIDE;
    int columnCount(const QModelIndex &parent=QModelIndex()) const Q_DECL_OVERRIDE;
    QModelIndex index(int row, int column, const QModelIndex &parent=QModelIndex()) const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex &index, int role=Qt::DisplayRole) const Q_DECL_OVERRIDE;
    QModelIndex parent(const QModelIndex &child) const Q_DECL_OVERRIDE;
    QHash<int,QByteArray> roleNames() const Q_DECL_OVERRIDE;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool CANPlay(bool play);
    Q_INVOKABLE void setCANProperty(int index, QString port, QString stime, QString etime);
    Q_INVOKABLE void setLogFileIndex(int index);
    Q_INVOKABLE QStringList getPortsList();
    Q_INVOKABLE QStringList getCanLogTime(QString port);
    Q_INVOKABLE bool checkTime(QString port, QString stime, QString etime);

private:
    QString convertTimeFormat(QString time);

private:
    QHash<int,QByteArray> roles;
    QList<QHash<int,QVariant>> datas;
    std::map<QString, QStringList> startTime;
    std::map<QString, QStringList> endTime;
    QStringList portsList;

    static const std::string PlayUtilsExec;

    pid_t playUtils;
    std::map<QString, QString> playUtilsArg;
};

#endif // LOGPLAYIMPPL_H
