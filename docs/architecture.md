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

Native Cython/C extensions now have their own `nativeExtensions` derivation.
Both the minimal runtime and full SDK consume that same compiled component.
It contains package extensions and the top-level `_renpy` extension. Their
assembly derivations compile Python/common scripts and copy or link native
extensions; they never invoke `build_ext` or `install_lib` again.

The full SDK still compiles its bundled examples and common scripts separately
from the minimal runtime. Splitting common scripts further is possible, but
native compilation is the expensive boundary and now genuinely shared.

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
version startup and test fixture compilation, not interactive graphics or save/load.

## Next boundaries

- Validate interactive rendering and save/load on both supported Linux systems.
- Factor common scripts further if their compilation cost justifies it.
- Exercise interactive launcher rendering and save/load.
- Add explicit versioned package sets when multiple engine versions are maintained.
- Treat web, Android and portable distribution toolchains as optional components,
  each with their own dependencies and checks.

## Initial validation

`nix flake check` passed on x86_64-linux: runtime version startup, test-project
compilation/lint, installed compiled-script presence, packaged command startup,
and rejection of an unsafe executable name. The native engine was substituted
from the Nix binary cache using the source-build derivation; this session did
not force a fresh Cython compilation. Both Linux systems passed flake evaluation.
This describes the initial milestone. See the component milestone below for
subsequent SDK and source-build validation.


## Component milestone

The native engine extensions are built from source in this milestone. A Python
integration fixture imports Pillow and calls its image API during project init;
this exercises the existing nixpkgs package-set extension hook.

The SDK patches component installation, Android SDK installation, local addon
ZIP installation and SDK updates to explain Nix management before touching its
installation. Update-channel fetching returns an empty list. Launcher project
scratch directories use the system temporary directory instead of the SDK.
Patched launcher scripts are compiled before installation. These changes do not
claim that every launcher function has been validated as immutable; editor
integration and interactive workflows still need separate checks.

### Web foundations

The Web dependency set is pinned to the renpy-build revision from 2026-05-17,
aligned in date with the existing engine source pin. Its source tasks choose
Emscripten 3.1.67 and CPython 3.12.8. Alignment in date is not yet an engine/runtime
compatibility guarantee; complete engine linking and browser tests remain.

Emscripten is packaged from its source scripts with nixpkgs LLVM 19.1.7 and a
source-built Binaryen 119. This is not the exact emsdk binary bundle. Binaryen
includes the upstream GCC 16 compatibility fix, backported from commit
2ff34a2e8adfddc35c32cb0180eed22477fe0553. Its normal DWARF support remains enabled.

zlib 1.3.1, bzip2 1.0.8 and xz 5.4.2 use individually hashed source tarballs from
the pinned upstream repository. Each library builds into a separate wasm archive.
No emsdk installer, pip download, or Emscripten ports fetch is used. Each build
uses a disposable HOME and EM_CACHE, outside the immutable installation.

The target CPython is a library/sysroot component for subsequent engine linking,
not a supported standalone Python executable. It consumes those libraries and the upstream static-module
list. A host Python from nixpkgs performs generation and installation work;
the target Python is never used as a build-host executable. The upstream opcode
transformation is retained for the future Ren'Py Web link stage.

The compression check links all three wasm libraries and executes real
compression/decompression round trips in Node. The Python artifact check
verifies the installed archive, its Wasm object format, headers and standard library. This alone does
not establish browser execution or full Ren'Py Web compatibility.

There is deliberately no `web.runtime` or Web game builder yet: SDL, image/text
libraries, FFmpeg, engine extensions, linking and browser execution remain to be
implemented. Android, Windows and macOS are planned; iOS is excluded.


### Validation results

The component milestone passes seven x86_64-linux flake checks: native runtime,
compiled test fixture, invalid-name contract, a project using Pillow, SDK startup and
compiled updater, Wasm compression round trips, and target Python artifacts.
Linux engine extensions, Binaryen, Web compression libraries and target Python
were compiled from source locally. Both Linux systems pass evaluation; aarch64
execution and interactive launcher/browser rendering remain unverified.
