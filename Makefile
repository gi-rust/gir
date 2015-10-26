include vars.mk

CONFIGURE_VARS = \
  CFLAGS='$(CFLAGS)' \
  CPPFLAGS='$(CPPFLAGS)' \
  LDFLAGS='$(LDFLAGS)' \
  PKG_CONFIG_PATH='$(build_PKG_CONFIG_PATH)'

export CFLAGS CPPFLAGS LDFLAGS

all: update-glib-annotations
	$(MAKE) -f Makefile-gir PKG_CONFIG_PATH='$(build_PKG_CONFIG_PATH)'

clean:
	-rm -r $(builddir)

.PHONY: all clean

autogen_submodules = src/glib src/gobject-introspection
autogen_scripts = $(addsuffix /autogen.sh,$(autogen_submodules))
configure_scripts = $(addsuffix /configure,$(autogen_submodules))

$(autogen_scripts):
	git submodule update --init $(dir $@)

$(configure_scripts): %/configure: %/autogen.sh
	cd $(dir $@) && NOCONFIGURE=1 ./autogen.sh

$(glib_builddir)/Makefile: src/glib/configure
	mkdir -p $(glib_builddir)
	cd $(glib_builddir) && \
	  $(CURDIR)/src/glib/configure \
	    --prefix=$(abs_build_installdir) \
	    $(CONFIGURE_VARS)

.PHONY: build-install-glib

build-install-glib: $(glib_builddir)/Makefile
	$(MAKE) -C $(glib_builddir)
	$(MAKE) -C $(glib_builddir) install INSTALL='install -p'

$(build_installdir)/lib/pkgconfig/*.pc: build-install-glib

$(gi_builddir)/Makefile: src/gobject-introspection/configure $(build_installdir)/lib/pkgconfig/*.pc
	mkdir -p $(gi_builddir)
	cd $(gi_builddir) && \
	  $(CURDIR)/src/gobject-introspection/configure \
	    --prefix=$(abs_build_installdir) \
	    --with-glib-src=../../src/glib \
	    $(CONFIGURE_VARS)

glib_gir_srcfiles = $(foreach lib,$(GLIB_PACKAGES),src/gobject-introspection/gir/$(lib).c)

.PHONY: update-glib-annotations

update-glib-annotations: $(gi_builddir)/Makefile build-install-glib
# Work around an issue with parallel builds
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C $(gi_builddir) scannerparser.h
	$(PKG_CONFIG_ENVIRONMENT) $(MAKE) -C $(gi_builddir) g-ir-annotation-tool
	for p in $(glib_gir_srcfiles); do \
	  cp -p $$p $$p.save; \
	done
	cd src/gobject-introspection/misc && \
	  $(PKG_CONFIG_ENVIRONMENT) ./update-glib-annotations.py \
	    ../../glib $(abspath $(gi_builddir))
	for p in $(glib_gir_srcfiles); do \
	  if cmp -s $$p $$p.save; then \
	    mv -f $$p.save $$p; \
	  else \
	    rm -f $$p.save; \
	  fi; \
	done
