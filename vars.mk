GLIB_NAMESPACES = GLib-2.0 GObject-2.0 GModule-2.0 Gio-2.0
GLIB_GIRFILES = $(addsuffix .gir,$(GLIB_NAMESPACES))
GLIB_PACKAGES := $(shell echo $(GLIB_NAMESPACES) | tr A-Z a-z)

submodules = src/glib src/gobject-introspection

builddir = build
glib_builddir = $(builddir)/glib
gi_builddir = $(builddir)/gobject-introspection
build_installdir = $(builddir)/installed
abs_build_installdir = $(abspath $(build_installdir))

PKG_CONFIG_ENVIRONMENT = PKG_CONFIG_PATH=$(abs_build_installdir)/lib/pkgconfig
