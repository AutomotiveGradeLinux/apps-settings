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

#ifndef TOUCHLOGPLAY_H
#define TOUCHLOGPLAY_H

#include <QAbstractItemModel>

class TouchLogPlayImpl: public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(bool propTouchPlayFlag READ propTouchPlayFlag NOTIFY propTouchPlayFlagChanged)
public:
    explicit TouchLogPlayImpl(QObject *parent = 0);
    ~TouchLogPlayImpl();

    enum TouchLogPlayImplRoles {
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

    bool propTouchPlayFlag() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool touchPlay(bool play);
    Q_INVOKABLE void setTouchProperty(int index);
    Q_INVOKABLE void setLogFileIndex(int index);

    void propTouchPlayFlagChangedDelegate();
    static void finalizeChild(int sig);

signals:
    void propTouchPlayFlagChanged();

private:
    QHash<int,QByteArray> roles;
    QList<QHash<int,QVariant>> datas;

    static const std::string touchPlayUtilsExec;
    static void (*oldHandler)(int);

    pid_t touchPlayUtils;
    std::map<QString, QString> touchplayUtilsArg;

    static TouchLogPlayImpl *pointer;
    static bool touchPlayFlag;
};

#endif // TOUCHLOGPLAY_H
