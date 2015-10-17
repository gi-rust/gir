GLIB_NAMESPACES = GLib-2.0 GObject-2.0 GModule-2.0 Gio-2.0
GLIB_GIRFILES = $(foreach ns,$(GLIB_NAMESPACES),$(ns).gir)
GLIB_PACKAGES := $(shell echo $(GLIB_NAMESPACES) | tr A-Z a-z)

submodules = src/glib src/gobject-introspection

abs_build_installdir = $(abspath build/installed)

PKG_CONFIG_ENVIRONMENT = PKG_CONFIG_PATH=$(abs_build_installdir)/lib/pkgconfig

all: $(GLIB_GIRFILES)

clean:
	rm -r build

.PHONY: all clean

autogen_submodules = src/glib src/gobject-introspection
autogen_scripts = $(foreach mod,$(autogen_submodules),$(mod)/autogen.sh)
configure_scripts = $(foreach mod,$(autogen_submodules),$(mod)/configure)

$(autogen_scripts):
	git submodule update --init $(dir $@)

$(configure_scripts): %/configure: %/autogen.sh
	cd $(dir $@) && NOCONFIGURE=1 ./autogen.sh

build/glib/Makefile: src/glib/configure
	mkdir -p build/glib
	cd build/glib && \
	  ../../src/glib/configure --prefix=$(abs_build_installdir)

build/.glib.build-stamp: build/glib/Makefile
	$(MAKE) -C build/glib && touch $@

build/.glib.install-stamp: build/.glib.build-stamp
	$(MAKE) -C build/glib install && touch $@

build/gobject-introspection/Makefile: src/gobject-introspection/configure build/.glib.install-stamp
	mkdir -p build/gobject-introspection
	cd build/gobject-introspection && \
	  $(PKG_CONFIG_ENVIRONMENT) ../../src/gobject-introspection/configure \
	    --prefix=$(abs_build_installdir) \
	    --with-glib-src=../../src/glib

$(GLIB_GIRFILES): %.gir: build/gobject-introspection/%.gir
	install -m644 $< $@

glib_gir_srcfiles = $(foreach lib,$(GLIB_PACKAGES),src/gobject-introspection/gir/$(lib).c)

$(glib_gir_srcfiles): build/.glib.build-stamp | update-glib-annotations

.PHONY: update-glib-annotations

update-glib-annotations: build/.glib.build-stamp build/gobject-introspection/Makefile
	# Work around an issue with parallel builds
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection scannerparser.h
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection g-ir-annotation-tool
	cd src/gobject-introspection/misc && \
	  $(PKG_CONFIG_ENVIRONMENT) ./update-glib-annotations.py ../../glib ../../../build/gobject-introspection

define build_gir
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection $(notdir $@)
endef

build/gobject-introspection/GLib-2.0.gir: src/gobject-introspection/gir/glib-2.0.c build/.glib.install-stamp
	$(build_gir)

build/gobject-introspection/GObject-2.0.gir: src/gobject-introspection/gir/gobject-2.0.c build/gobject-introspection/GLib-2.0.gir build/.glib.install-stamp
	$(build_gir)

build/gobject-introspection/GModule-2.0.gir: src/gobject-introspection/gir/gmodule-2.0.c build/gobject-introspection/GLib-2.0.gir build/.glib.install-stamp
	$(build_gir)

build/gobject-introspection/Gio-2.0.gir: src/gobject-introspection/gir/gio-2.0.c build/gobject-introspection/GObject-2.0.gir build/.glib.install-stamp
	$(build_gir)
