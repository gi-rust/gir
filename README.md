This repository contains the GIR files used to generate Rust crates
of the GI-Rust project. It also has the build files and submodule
references to the source projects used to generate the GIR files.

# Building

To rebuild the GIR files, change into the working directory of the cloned
repository and run `make`. GNU make is required.

Bootstrapping of the build involves cloning the submodules from their GNOME
git repositories. If you have the GNOME repositories already cloned locally,
you can avoid excessive transfers by initializing the submodules with those
local clones as reference repositories:

```sh
git submodule update --init --reference ~/my-repos/glib src/glib
git submodule update --init --reference ~/my-repos/gobject-introspection src/gobject-introspection
```
