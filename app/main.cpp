/*
 * Copyright (C) 2016 The Qt Company Ltd.
 * Copyright (C) 2017 Konsulko Group
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
#include <QQuickWindow>
#include <libhomescreen.hpp>
#include <bluetooth.h>
#include <qlibwindowmanager.h>

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
    QString myname = QString("Settings");

    QGuiApplication app(argc, argv);
    app.setApplicationName(myname);
    app.setApplicationVersion(QStringLiteral("0.1.0"));
    app.setOrganizationDomain(QStringLiteral("automotivelinux.org"));
    app.setOrganizationName(QStringLiteral("AutomotiveGradeLinux"));

    QQuickStyle::setStyle("AGL");

    QCommandLineParser parser;
    parser.addPositionalArgument("port", app.translate("main", "port for binding"));
    parser.addPositionalArgument("secret", app.translate("main", "secret for binding"));
    parser.addHelpOption();
    parser.addVersionOption();
    parser.process(app);
    QStringList positionalArguments = parser.positionalArguments();

    QQmlApplicationEngine engine;
    if (positionalArguments.length() != 2) {
        exit(EXIT_FAILURE);
    }
    int port = positionalArguments.takeFirst().toInt();
    QString secret = positionalArguments.takeFirst();
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("token"), secret);

    QUrl bindingAddressWS;
    bindingAddressWS.setScheme(QStringLiteral("ws"));
    bindingAddressWS.setHost(QStringLiteral("localhost"));
    bindingAddressWS.setPort(port);
    bindingAddressWS.setPath(QStringLiteral("/api"));
    bindingAddressWS.setQuery(query);
    QQmlContext *context = engine.rootContext();
    context->setContextProperty(QStringLiteral("bindingAddressWS"), bindingAddressWS);

    std::string token = secret.toStdString();
    LibHomeScreen* hs = new LibHomeScreen();
    QLibWindowmanager* qwm = new QLibWindowmanager();

    // WindowManager
    if(qwm->init(port,secret) != 0) {
        exit(EXIT_FAILURE);
    }
    // Request a surface as described in layers.json windowmanager’s file
    if(qwm->requestSurface(myname) != 0) {
        exit(EXIT_FAILURE);
    }
    // Create an event callback against an event type. Here a lambda is called when SyncDraw event occurs
    qwm->set_event_handler(QLibWindowmanager::Event_SyncDraw, [qwm, myname](json_object *object) {
	  fprintf(stderr, "Surface got syncDraw!\n");
	  qwm->endDraw(myname);
      });

    // HomeScreen
    hs->init(port, token.c_str());
    // Set the event handler for Event_TapShortcut which will activate the surface for windowmanager
    hs->set_event_handler(LibHomeScreen::Event_TapShortcut, [qwm, myname](json_object *object){
        json_object *appnameJ = nullptr;
        if(json_object_object_get_ex(object, "application_name", &appnameJ))
        {
            const char *appname = json_object_get_string(appnameJ);
            if(myname == appname)
            {
                qDebug("Surface %s got tapShortcut\n", appname);
                qwm->activateSurface(myname);
            }
        }
    });

    QFile version("/proc/version");
    if (version.open(QFile::ReadOnly)) {
        QStringList data = QString::fromLocal8Bit(version.readAll()).split(QLatin1Char(' '));
        engine.rootContext()->setContextProperty("kernel", data.at(2));
        version.close();
    } else {
        qWarning() << version.errorString();
    }

    QFile aglversion("/etc/os-release");
    if (aglversion.open(QFile::ReadOnly)) {
        QStringList data = QString::fromLocal8Bit(aglversion.readAll()).split(QLatin1Char('\n'));
        QStringList data2 = data.at(2).split(QLatin1Char('"'));
        engine.rootContext()->setContextProperty("ucb", data2.at(1));
        aglversion.close();
    } else {
        qWarning() << aglversion.errorString();
    }

    DBus dbus;
    engine.rootContext()->setContextProperty("dbus", &dbus);
    engine.rootContext()->setContextProperty("bluetooth", new Bluetooth(bindingAddressWS));
    engine.load(QUrl(QStringLiteral("qrc:/Settings.qml")));
    QObject *root = engine.rootObjects().first();
    QQuickWindow *window = qobject_cast<QQuickWindow *>(root);
    QObject::connect(window, SIGNAL(frameSwapped()), qwm, SLOT(slotActivateSurface()));

    return app.exec();
}

#include "main.moc"
