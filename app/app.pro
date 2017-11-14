TARGET = settings
QT = quickcontrols2 dbus

SOURCES = main.cpp

CONFIG += link_pkgconfig
PKGCONFIG += libhomescreen qlibwindowmanager

RESOURCES += \ 
    settings.qrc \
    images/images.qrc \
    datetime/datetime.qrc \
    wifi/wifi.qrc \
    bluetooth/bluetooth.qrc \
    example/example.qrc \
    version/version.qrc


include(app.pri)
