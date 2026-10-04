# renpy-nix

A small Nix-native integration for normal Ren'Py projects. The first milestone
supports native Linux builds on x86_64 and aarch64; cross compilation and
standalone distributions are outside the current API.

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
`renpyPackages.source` exposes the pinned engine source.
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
