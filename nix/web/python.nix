{
  lib,
  stdenvNoCC,
  python312,
  buildSource,
  src,
  toolchain,
  zlib,
  bzip2,
  xz,
  environment,
}:
let
  buildPython = python312.withPackages (ps: [ ps.jinja2 ]);
  includes = lib.concatMapStringsSep " " (p: "-I${p}/include") [
    zlib
    bzip2
    xz
  ];
  libraries = lib.concatMapStringsSep " " (p: "-L${p}/lib") [
    zlib
    bzip2
    xz
  ];
in
stdenvNoCC.mkDerivation {
  pname = "renpy-web-python";
  version = "3.12.8";
  inherit src;
  nativeBuildInputs = [
    toolchain
    buildPython
  ];
  strictDeps = true;
  dontStrip = true;
  dontPatchELF = true;
  enableParallelBuilding = true;
  configurePhase = ''
    runHook preConfigure
    ${environment}
    export CFLAGS="-O2 ${includes}" CPPFLAGS="${includes}" LDFLAGS="${libraries}"
    export CONFIG_SITE=Tools/wasm/config.site-wasm32-emscripten
    emconfigure ./configure --host=wasm32-unknown-emscripten --build=${stdenvNoCC.buildPlatform.config} \
      --prefix="$out" --with-emscripten-target=browser --with-ensurepip=no \
      --with-build-python=${buildPython}/bin/python3.12
    ${buildPython}/bin/python ${./render-setup.py} \
      ${buildSource}/source/Python-3.12.8-Setup.stdlib Modules/Setup.stdlib
    cp Modules/Setup.stdlib Modules/Setup
    runHook postConfigure
  '';
  buildPhase = ''
    runHook preBuild
    make -j$NIX_BUILD_CORES
    python ${buildSource}/tools/opfunc/opfunc_transform.py Python/ceval.c
    make -j$NIX_BUILD_CORES
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    # Avoid running the browser-target executable or attempting ensurepip.
    make install -j$NIX_BUILD_CORES
    runHook postInstall
  '';
  meta = {
    description = "Source-built browser-target CPython for Ren'Py";
    platforms = lib.platforms.linux;
    license = lib.licenses.psfl;
  };
}
