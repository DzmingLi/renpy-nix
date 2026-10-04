{ pkgs }:
let
  buildSource = import ../sources.nix { inherit pkgs; };
  sources = import ./sources.nix { inherit pkgs; };
  toolchain = import ./toolchain.nix { inherit pkgs; };
  environment = ''
    export HOME=$TMPDIR/home EM_CACHE=$TMPDIR/emscripten-cache
    mkdir -p "$HOME" "$EM_CACHE"
    export CC=emcc CXX=em++ AR=emar RANLIB=emranlib NM=emnm
  '';
  common = {
    nativeBuildInputs = [
      toolchain
      pkgs.python3
    ];
    dontStrip = true;
    dontPatchELF = true;
    strictDeps = true;
    enableParallelBuilding = true;
    meta.platforms = pkgs.lib.platforms.linux;
  };
  zlib = pkgs.stdenvNoCC.mkDerivation (
    common
    // {
      pname = "renpy-web-zlib";
      version = "1.3.1";
      src = sources.zlib;
      configurePhase = ''
        runHook preConfigure
        ${environment}
        emconfigure ./configure --static --prefix="$out"
        runHook postConfigure
      '';
    }
  );
  bzip2 = pkgs.stdenvNoCC.mkDerivation (
    common
    // {
      pname = "renpy-web-bzip2";
      version = "1.0.8";
      src = sources.bzip2;
      dontConfigure = true;
      buildPhase = ''
        runHook preBuild
        ${environment}
        make -j$NIX_BUILD_CORES libbz2.a CC=emcc AR=emar RANLIB=emranlib CFLAGS="-O2 -D_FILE_OFFSET_BITS=64"
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        install -Dm644 libbz2.a "$out/lib/libbz2.a"
        install -Dm644 bzlib.h "$out/include/bzlib.h"
        runHook postInstall
      '';
    }
  );
  xz = pkgs.stdenvNoCC.mkDerivation (
    common
    // {
      pname = "renpy-web-xz";
      version = "5.4.2";
      src = sources.xz;
      configurePhase = ''
        runHook preConfigure
        ${environment}
        emconfigure ./configure --host=wasm32-unknown-emscripten --prefix="$out" \
          --enable-static --disable-shared --disable-threads \
          --disable-xz --disable-xzdec --disable-lzmadec --disable-lzmainfo --disable-scripts --disable-doc
        runHook postConfigure
      '';
    }
  );
  python = pkgs.callPackage ./python.nix {
    inherit
      buildSource
      toolchain
      zlib
      bzip2
      xz
      environment
      ;
    src = sources.python;
  };
in
{
  inherit toolchain python;
  libraries = { inherit zlib bzip2 xz; };
  # No web runtime attribute until engine linking and browser execution pass.
}
