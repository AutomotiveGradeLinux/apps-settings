TARGET = settings
QT = quickcontrols2 dbus

SOURCES = main.cpp

RESOURCES += \ 
    settings.qrc \
    images/images.qrc \
    datetime/datetime.qrc \
    wifi/wifi.qrc \
    bluetooth/bluetooth.qrc \
    example/example.qrc


include(app.pri)
