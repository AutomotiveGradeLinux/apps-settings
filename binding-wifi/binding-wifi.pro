TARGET = settings-wifi-binding

HEADERS = wifi-api.h wifi-connman.h
SOURCES = agent.c wifi-api.c wifi-connman.c

LIBS += -Wl,--version-script=$$PWD/export.map

CONFIG += link_pkgconfig
PKGCONFIG += json-c afb-daemon glib-2.0 gio-2.0 gobject-2.0 zlib

include(binding.pri)
