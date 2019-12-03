TARGET = settings
QT = quickcontrols2 websockets

SOURCES = main.cpp

CONFIG += link_pkgconfig
PKGCONFIG += libhomescreen qlibwindowmanager qtappfw

RESOURCES += \
    settings.qrc \
    images/images.qrc \
    datetime/datetime.qrc \
    wifi/wifi.qrc \
    wired/wired.qrc \
    bluetooth/bluetooth.qrc \
    version/version.qrc \
    voice/voice.qrc

include(app.pri)
