This repository contains the GIR files used to generate Rust crates
of the GI-Rust project. It also has the build files and submodule
references to the source projects used to generate the GIR files.

# Building

To rebuild the GIR files, change into the working directory of the cloned
repository and run `make`. GNU make is required. **Caveat:** The initial
build will clone the submodules, some of which have history stretching back
to 1998; read below on ways to limit the amount of fetching.

## Optimizing the initial fetch

Bootstrapping of the build involves cloning the submodules originating in
GNOME git repositories. If you have the GNOME repositories already cloned
locally, you can avoid excessive transfers by initializing the submodules
with those local clones as reference repositories:

```sh
git submodule update --init --reference ~/my-repos/glib src/glib
git submodule update --init --reference ~/my-repos/gobject-introspection src/gobject-introspection
```

In non-development setups such as continuous integration builds,
shallow clones can be useful:

```sh
git submodule update --init --depth 40
# git complains about an unreachable reference
# in origin/rust-fixes/*; fix below
cd src/glib
git remote set-branches --add origin rust-fixes/master rust-fixes/glib-2-46
cd ../..
git submodule update --remote --depth 40 src/glib
```

## Dependencies

The tools and libraries required for building include:

* GNU make
* GNU autotools (autoconf, automake, libtool)
* pkg-config
* Python 2.x and 3.x in a side-by-side installation; the Python 3
  executable should be found in `PATH` as `python3`.
* External build dependencies of glib and gobject-introspection.

Make variables `CPPFLAGS`, `LDFLAGS`, `PKG_CONFIG_PATH` are
passed to configure and sub-make invocations; by setting custom values
to these variables, path to dependencies in non-default locations
can be resolved.

## Mac OS X

On Mac OS X, Command Line Tools for XCode should be installed.

A practical way to install dependencies is with
[Homebrew](http://brew.sh/):

```sh
brew install autoconf automake libtool pkg-config gettext libffi
export PATH=$PATH:/usr/local/opt/gettext/bin
```

Installation of Python 3 from Homebrew may be problematic, so it's
best to use the installer from the [website](http://www.python.org/).

With the dependencies installed as above, build with the following command:

```sh
make CPPFLAGS='-I/usr/local/opt/gettext/include' \
     LDFLAGS='-L/usr/local/opt/gettext/lib' \
     PKG_CONFIG_PATH='/usr/local/opt/libffi/lib/pkgconfig'
```
