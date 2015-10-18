GLIB_NAMESPACES = GLib-2.0 GObject-2.0 GModule-2.0 Gio-2.0
GLIB_GIRFILES = $(foreach ns,$(GLIB_NAMESPACES),$(ns).gir)
GLIB_PACKAGES := $(shell echo $(GLIB_NAMESPACES) | tr A-Z a-z)

submodules = src/glib src/gobject-introspection

abs_build_installdir = $(abspath build/installed)

PKG_CONFIG_ENVIRONMENT = PKG_CONFIG_PATH=$(abs_build_installdir)/lib/pkgconfig

export GLIB_GIRFILES PKG_CONFIG_ENVIRONMENT

all: update-glib-annotations
	$(MAKE) -f Makefile.gir

clean:
	-rm -r build

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

.PHONY: build-install-glib

build-install-glib: build/glib/Makefile
	$(MAKE) -C build/glib
	$(MAKE) -C build/glib install INSTALL='install -p'

build/installed/lib/pkgconfig/*.pc: build-install-glib

build/gobject-introspection/Makefile: src/gobject-introspection/configure build/installed/lib/pkgconfig/*.pc
	mkdir -p build/gobject-introspection
	cd build/gobject-introspection && \
	  $(PKG_CONFIG_ENVIRONMENT) ../../src/gobject-introspection/configure \
	    --prefix=$(abs_build_installdir) \
	    --with-glib-src=../../src/glib

glib_gir_srcfiles = $(foreach lib,$(GLIB_PACKAGES),src/gobject-introspection/gir/$(lib).c)

.PHONY: update-glib-annotations

update-glib-annotations: build/gobject-introspection/Makefile build-install-glib
# Work around an issue with parallel builds
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection scannerparser.h
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C build/gobject-introspection g-ir-annotation-tool
	for p in $(glib_gir_srcfiles); do \
	  cp -p $$p $$p.save; \
	done
	cd src/gobject-introspection/misc && \
	  $(PKG_CONFIG_ENVIRONMENT) ./update-glib-annotations.py ../../glib ../../../build/gobject-introspection
	for p in $(glib_gir_srcfiles); do \
	  if cmp -s $$p $$p.save; then \
	    mv -f $$p.save $$p; \
	  else \
	    rm -f $$p.save; \
	  fi; \
	done
