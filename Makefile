GLIB_GIRFILES = GLib-2.0.gir GObject-2.0.gir GModule-2.0.gir Gio-2.0.gir
GLIB_PACKAGES = glib-2.0 gobject-2.0 gmodule-2.0 gio-2.0

abs_build_installdir = $(abspath build/installed)

PKG_CONFIG_ENVIRONMENT = PKG_CONFIG_PATH=$(abs_build_installdir)/lib/pkgconfig

all: $(GLIB_GIRFILES)

clean:
	rm -r build

.PHONY: all clean

src/glib: .gitmodules
	git submodule update --init src/glib

src/gobject-introspection: .gitmodules
	git submodule update --init src/gobject-introspection

src/glib/autogen.sh: | src/glib
src/gobject-introspection/autogen.sh: | src/gobject-introspection

src/glib/configure: src/glib/autogen.sh
	cd src/glib && NOCONFIGURE=1 ./autogen.sh

src/gobject-introspection/configure: src/gobject-introspection/autogen.sh
	cd src/gobject-introspection && NOCONFIGURE=1 ./autogen.sh

build/glib/Makefile: src/glib/configure
	mkdir -p build/glib
	cd build/glib && \
	  ../../src/glib/configure --prefix=$(abs_build_installdir)

.PHONY: update-submodule-glib update-submodule-gobject-introspection

update-submodule-glib:
	git submodule update src/glib

update-submodule-gobject-introspection:
	git submodule update src/gobject-introspection

build/.glib.build-stamp: .gitmodules build/glib/Makefile | update-submodule-glib
	$(MAKE) -C build/glib && touch $@

build/.glib.install-stamp: build/.glib.build-stamp
	$(MAKE) -C build/glib install && touch $@

build/gobject-introspection/Makefile: src/gobject-introspection/configure build/.glib.install-stamp
	mkdir -p build/gobject-introspection
	cd build/gobject-introspection && \
	  $(PKG_CONFIG_ENVIRONMENT) ../../src/gobject-introspection/configure \
	    --prefix=$(abs_build_installdir) \
	    --with-glib-src=../../src/glib

build/gobject-introspection/g-ir-annotation-tool: .gitmodules build/gobject-introspection/Makefile | update-submodule-gobject-introspection
	# Work around an issue with parallel builds
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection scannerparser.h
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection g-ir-annotation-tool

$(GLIB_GIRFILES): %.gir: build/gobject-introspection/%.gir
	install -m644 $< $@

glib_gir_srcfiles = $(foreach lib,$(GLIB_PACKAGES),build/gobject-introspection/gir/$(lib).c)

$(glib_gir_srcfiles): build/.glib.build-stamp | update-glib-annotations

.PHONY: update-glib-annotations

update-glib-annotations: build/.glib.build-stamp update-submodule-gobject-introspection build/gobject-introspection/g-ir-annotation-tool
	cd src/gobject-introspection/misc && \
	  $(PKG_CONFIG_ENVIRONMENT) ./update-glib-annotations.py ../../glib ../../../build/gobject-introspection

build/gobject-introspection/GLib-2.0.gir: build/gobject-introspection/gir/glib-2.0.c build/.glib.install-stamp
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection GLib-2.0.gir

build/gobject-introspection/GObject-2.0.gir: build/gobject-introspection/gir/gobject-2.0.c build/gobject-introspection/GLib-2.0.gir build/.glib.install-stamp
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection GObject-2.0.gir

build/gobject-introspection/GModule-2.0.gir: build/gobject-introspection/gir/gmodule-2.0.c build/gobject-introspection/GLib-2.0.gir build/.glib.install-stamp
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection GModule-2.0.gir

build/gobject-introspection/Gio-2.0.gir: build/gobject-introspection/gir/gio-2.0.c build/gobject-introspection/GObject-2.0.gir build/.glib.install-stamp
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection Gio-2.0.gir
