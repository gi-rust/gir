GLIB_NAMESPACES = GLib-2.0 GObject-2.0 GModule-2.0 Gio-2.0
GLIB_GIRFILES = $(addsuffix .gir,$(GLIB_NAMESPACES))
GLIB_PACKAGES := $(shell echo $(GLIB_NAMESPACES) | tr A-Z a-z)

builddir = build
glib_builddir = $(builddir)/glib
gi_builddir = $(builddir)/gobject-introspection
build_installdir = $(builddir)/installed
abs_build_installdir = $(abspath $(build_installdir))
build_install_pkg_config_dir = $(abs_build_installdir)/lib/pkgconfig

# Would have been -O0, but g-ir-scanner emits cpp warnings
# about _FORTIFY_SOURCE
CFLAGS = -O1
CPPFLAGS =
LDFLAGS =
PKG_CONFIG_PATH =

build_PKG_CONFIG_PATH = $(build_install_pkg_config_dir):$(PKG_CONFIG_PATH)

PKG_CONFIG_ENVIRONMENT = PKG_CONFIG_PATH=$(build_PKG_CONFIG_PATH)
