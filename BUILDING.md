# Building and exporting duplicate-remover

## Building

### Windows

Use [`build.bat`](./build.bat) to automatically build.

Manual build instructions:

- Locate to project root.

- Build using dub:

```sh
dub build -c cli
dub build -c gui-windows 
```

- The GUI app has additional dependencies. `lib/` holds one such version of these
dependencies. Copy the `.dll` libraries from `lib/windows/` into the build
destination.

### Linux

Use [`build.sh`](./build.sh) to automatically build.

Manual build instructions:

- Locate to project root.

- Build using dub:

```sh
dub build -c cli
dub build -c gui-linux 
```

- The GUI app has additional dependencies. `lib/` holds one such version of these
dependencies. Copy the `.so` libraries from `lib/linux/` into the build
destination.

- Set binaries folder to $ORIGIN so that the GUI program can load `.so` files
locally:

```sh
patchelf --set-rpath '$ORIGIN' ./bin/duplicate_remover_gui
```

---

- **TODO**: Continunous publishing