TEMPLATE = subdirs
SUBDIRS = app binding-wifi binding-bluetooth package
package.depends += app binding-wifi binding-bluetooth
