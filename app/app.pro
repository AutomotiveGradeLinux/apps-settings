TEMPLATE = app
TARGET = settings
QT = qml quickcontrols2
CONFIG += c++11 link_pkgconfig

PKGCONFIG += qtappfw-network qtappfw-bt

SOURCES = main.cpp

RESOURCES += \
    settings.qrc \
    images/images.qrc \
    datetime/datetime.qrc \
    wifi/wifi.qrc \
    wired/wired.qrc \
    bluetooth/bluetooth.qrc \
    version/version.qrc

target.path = /usr/bin
target.files += $${OUT_PWD}/$${TARGET}
target.CONFIG = no_check_exist executable

INSTALLS += target
