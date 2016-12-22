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

#include <QtCore/QDebug>
#include <QtCore/QCommandLineParser>
#include <QtCore/QUrlQuery>
#include <QtCore/QFile>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusReply>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQuickControls2/QQuickStyle>

#ifdef HAVE_LIBHOMESCREEN
#include <libhomescreen.hpp>
#endif

class DBus : public QObject
{
    Q_OBJECT
public:
    DBus(QObject *parent = nullptr)
        : QObject(parent)
        , interface("org.agl.homescreen", "/StatusBar", "org.agl.statusbar", QDBusConnection::sessionBus())
    {}

    Q_INVOKABLE void setStatusIcon(int index, const QString &url) {
        interface.call("setStatusIcon", index, url);
    }

private:
    QDBusInterface interface;
};

int main(int argc, char *argv[])
{
#ifdef HAVE_LIBHOMESCREEN
    LibHomeScreen libHomeScreen;

    if (!libHomeScreen.renderAppToAreaAllowed(0, 1)) {
        qWarning() << "renderAppToAreaAllowed is denied";
        return -1;
    }
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("HVAC"));
    app.setApplicationVersion(QStringLiteral("0.1.0"));
    app.setOrganizationDomain(QStringLiteral("automotivelinux.org"));
    app.setOrganizationName(QStringLiteral("AutomotiveGradeLinux"));

    QQuickStyle::setStyle("AGL");

    QCommandLineParser parser;
    parser.addPositionalArgument("port", app.translate("main", "port for binding"));
//    parser.addPositionalArgument("secret", app.translate("main", "secret for binding"));
    parser.addHelpOption();
    parser.addVersionOption();
    parser.process(app);
    QStringList positionalArguments = parser.positionalArguments();


    QQmlApplicationEngine engine;
    int port = 0;
    if (!positionalArguments.isEmpty()) {
        port = positionalArguments.takeFirst().toInt();
    }
//        QString secret = positionalArguments.takeFirst();
    QUrl bindingAddress;
    bindingAddress.setScheme(QStringLiteral("http"));
    bindingAddress.setHost(QStringLiteral("localhost"));
    bindingAddress.setPort(port);
    bindingAddress.setPath(QStringLiteral("/api"));
//        QUrlQuery query;
//        query.addQueryItem(QStringLiteral("token"), secret);
//        bindingAddress.setQuery(query);
    QQmlContext *context = engine.rootContext();
    context->setContextProperty(QStringLiteral("bindingAddress"), bindingAddress);

    QFile version("/proc/version");
    if (version.open(QFile::ReadOnly)) {
        QStringList data = QString::fromLocal8Bit(version.readAll()).split(QLatin1Char(' '));
        engine.rootContext()->setContextProperty("kernel", data.at(2));
        version.close();
    } else {
        qWarning() << version.errorString();
    }
    DBus dbus;
    engine.rootContext()->setContextProperty("dbus", &dbus);
    engine.load(QUrl(QStringLiteral("qrc:/Settings.qml")));

    return app.exec();
}

#include "main.moc"
