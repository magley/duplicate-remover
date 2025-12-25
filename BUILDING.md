# Building and exporting duplicate-remover

## Building

### Windows

Locate to project root.

Build using dub:

```sh
dub build -c cli
dub build -c gui-windows 
```

### Linux

Locate to project root.

Build using dub:

```sh
dub build -c cli
dub build -c gui-linux 
```

Set binaries folder to $ORIGIN so that the GUI program can load `.so` files
locally:

```sh
patchelf --set-rpath '$ORIGIN' ./bin/duplicate_remover_gui
```

## Publishing

Make sure to build in release mode:

```sh
dub build --build=release ...
```

---

- **TODO**: Bundling libraries on Windows
- **TODO**: Bundling libraries on Linux
- **TODO**: Write scripts to automate this
- **TODO**: Continunous publishing