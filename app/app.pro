TARGET = settings
QT = quickcontrols2 websockets

HEADERS += \
    logfile/logsave.h \
    logfile/logplay.h \
    logfile/touchlogplay.h

SOURCES = main.cpp \
    logfile/logsave.cpp \
    logfile/logplay.cpp \
    logfile/touchlogplay.cpp

CONFIG += link_pkgconfig
PKGCONFIG += libhomescreen qlibwindowmanager qtappfw

RESOURCES += \ 
    settings.qrc \
    images/images.qrc \
    datetime/datetime.qrc \
    wifi/wifi.qrc \
    bluetooth/bluetooth.qrc \
    version/version.qrc \
    logfile/logfile.qrc


include(app.pri)
