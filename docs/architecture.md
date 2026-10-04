# Architecture decisions

## Reuse the native source build

The pinned nixpkgs Ren'Py expression builds Cython/native extensions from the
upstream source and compiles common scripts before installation. Reuse it through
`override` instead of copying its dependency list and downstream patches.
The flake pins nixpkgs, which in turn pins the exact Ren'Py source and its hash.
The current source version is 8.5.3.26051504-unstable-2026-05-17.

Sources:
- https://github.com/NixOS/nixpkgs/blob/0dad76d31d59d0f9e1e6b2404dd28044bba50a6d/pkgs/by-name/re/renpy/package.nix
- https://github.com/renpy/renpy
- https://www.renpy.org/doc/html/cli.html

## Component API, inspired by Fenix

Expose selectable components through a package set rather than hiding all
artifacts in one SDK. Runtime, SDK and source are explicit. This is a component
model, not a claim of Fenix-compatible APIs or multi-version channels.

The minimal runtime and full SDK currently compile separately because upstream
nixpkgs couples native compilation and common-script installation. They share
fetched sources and dependency derivations, but not the native compilation
result. A future engine-core/common-scripts/launcher split is worthwhile once
we own or upstream that builder boundary. Creating thin output copies would
not provide independent native compilation caching, so we do not pretend it does.

Games are separate derivations depending on an unchanged runtime. Changing a
game therefore does not rebuild the engine. Added Python packages form a small
wrapper derivation and a reusable Python environment rather than recompiling
the engine. Python dependencies must match its interpreter ABI; this API does
not replace an existing Python dependency workflow.

## Normal project input

A project is a source tree containing game/. Metadata such as the executable
name is Nix packaging metadata. Ren'Py configuration stays in options.rpy and
script.rpy. Compilation uses the upstream command in the Nix sandbox with dummy
SDL drivers and a temporary HOME. Lint can be disabled explicitly. Custom init
Python must respect sandbox restrictions during compile/lint.

The installed project is immutable. Compiled script files are produced before
installation; saves use Ren'Py's user save directory. Runtime smoke checks test
version startup and example compilation, not interactive graphics or save/load.

## Next boundaries

- Validate interactive rendering and save/load on both supported Linux systems.
- Factor the native engine and common scripts only when that creates real reuse.
- Add SDK launcher checks and externally supplied Python environment tests.
- Add explicit versioned package sets when multiple engine versions are maintained.
- Treat web, Android and portable distribution toolchains as optional components,
  each with their own dependencies and checks.

## Initial validation

`nix flake check` passed on x86_64-linux: runtime version startup, normal-project
compilation/lint, installed compiled-script presence, packaged command startup,
and rejection of an unsafe executable name. The native engine was substituted
from the Nix binary cache using the source-build derivation; this session did
not force a fresh Cython compilation. Both Linux systems passed flake evaluation.
The full SDK and interactive rendering have not been exercised locally.
