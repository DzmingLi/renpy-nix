# renpy-nix

A small Nix-native integration for normal Ren'Py projects. Native Linux builds are exposed for x86_64 and aarch64. Web cross-compilation
foundations are available as separate components; a complete Web game runtime
and standalone desktop distributions are not yet implemented. iOS is excluded.

```sh
nix flake check
nix build .#runtime
nix build .#hello
nix run
nix develop
renpy /path/to/project lint
```

## Overlay and builder

```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ renpy-nix.overlays.default ];
};
game = pkgs.mkRenpyProject {
  pname = "my-game";
  version = "1.0";
  src = ./my-game; # contains game/, no new manifest
  # projectSubdir = "visual-novel";
};
```

`renpyPackages.runtime` is the source-built minimal engine.
`renpyPackages.sdk` additionally includes the upstream launcher and examples,
without documentation or downloaded binary distribution libraries.
`renpyPackages.components.nativeExtensions` is a separate source-built Cython/C
component reused by runtime and SDK. `renpyPackages.source` exposes the pinned
engine source, and `renpyPackages.sources.build` the pinned upstream build recipes.
The SDK's component installers and updater explain that its installation is
managed by Nix; launcher scratch files use the system temporary directory.
`renpyPackages.mkProject` and `pkgs.mkRenpyProject` are the same builder.

The builder compiles scripts in a writable build directory, runs upstream lint
by default, installs game/ (including its assets), and wraps the native engine.
The lint report is installed alongside the game. Upstream lint is advisory:
its exit status alone does not establish that there are no warnings.
Root-level auxiliary files are not installed; put runtime assets inside game/.
Outputs depend on the Nix store and are not portable Ren'Py SDK distributions.

## Python integration

```nix
custom = pkgs.renpyPackages.withPythonPackages (ps: [ ps.pillow ]);
game = custom.mkProject {
  pname = "my-game";
  src = ./my-game;
};
```

Packages come from the pinned interpreter's existing nixpkgs Python package set.
The package-set constructor in `nix/packages.nix` accepts `python` as an
injection point for another compatible Python package set. Changing interpreter
versions requires rebuilding and checking engine compatibility. There is no
requirements parser, lockfile translator, pip install phase, or custom resolver.

See [architecture](docs/architecture.md) for boundaries and next steps.


## Web source-build foundations

```sh
nix build .#web-toolchain
nix build .#web-zlib .#web-bzip2 .#web-xz
nix build .#web-python
```

These map to `renpyPackages.web.toolchain`, `.libraries.{zlib,bzip2,xz}` and
`.python`. They package Emscripten 3.1.67, compile Binaryen 119 and build the
compression libraries and browser-target CPython 3.12.8 from pinned sources.
The Python component supplies the static archive, headers and standard library
for engine linking; it is not a standalone interpreter interface.
Builds use temporary writable caches and require no implicit dependency downloads.
LLVM comes from the existing pinned nixpkgs package set.

`nix flake check` includes wasm compression round trips executed in Node, target
Python installation checks, SDK startup and compilation, and a normal project
that imports Pillow through `withPythonPackages`.

There is no `web.runtime` yet. The remaining SDL/media/text/engine components and
browser tests are required before Web exports can be considered supported.
Android and Windows runtime source builds follow after that; macOS requires
separate host/toolchain validation.
