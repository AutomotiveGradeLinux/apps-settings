/*
 * Copyright (C) 2016 The Qt Company Ltd.
 * Copyright (C) 2017,2020 Konsulko Group
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

#include <QtCore/QDebug>
#include <QtCore/QCommandLineParser>
#include <QtCore/QUrlQuery>
#include <QtCore/QFile>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQuickControls2/QQuickStyle>
#include <QQuickWindow>
#include <bluetooth.h>
#include <network.h>

int main(int argc, char *argv[])
{
    QString graphic_role = QString("settings"); // defined in layers.json in window manager

    QGuiApplication app(argc, argv);

    app.setApplicationName(graphic_role);
    app.setApplicationVersion(QStringLiteral("0.1.1"));
    app.setOrganizationDomain(QStringLiteral("automotivelinux.org"));
    app.setOrganizationName(QStringLiteral("AutomotiveGradeLinux"));
    // necessary as the app_id will be a combination of 'automotivelinux.org'
    // and 'settings'
    app.setDesktopFileName(graphic_role);

    QQuickStyle::setStyle("AGL");

    QQmlApplicationEngine engine;
    QQmlContext *context = engine.rootContext();

    QFile version("/proc/version");
    if (version.open(QFile::ReadOnly)) {
        QStringList data = QString::fromLocal8Bit(version.readAll()).split(QLatin1Char(' '));
        context->setContextProperty("kernel", data.at(2));
        version.close();
    } else {
        qWarning() << version.errorString();
    }

    QFile aglversion("/etc/os-release");
    if (aglversion.open(QFile::ReadOnly)) {
        QStringList data = QString::fromLocal8Bit(aglversion.readAll()).split(QLatin1Char('\n'));
        QStringList data2 = data.at(2).split(QLatin1Char('"'));
        context->setContextProperty("ucb", data2.at(1));
        aglversion.close();
    } else {
        qWarning() << aglversion.errorString();
    }

    context->setContextProperty("bluetooth", new Bluetooth(true, context));
    context->setContextProperty("network", new Network(true, context));

    engine.load(QUrl(QStringLiteral("qrc:/Settings.qml")));

    return app.exec();
}
