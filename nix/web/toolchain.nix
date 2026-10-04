{ pkgs }:
let
  source = pkgs.fetchFromGitHub {
    owner = "emscripten-core";
    repo = "emscripten";
    rev = "3.1.67";
    hash = "sha256-811zBR/9UIrdGQsJXm+RrGE3hSlPYFFJjc9j4KQZIfM=";
  };
  llvm = pkgs.llvmPackages_19;
  llvmEnv = pkgs.symlinkJoin {
    name = "renpy-web-llvm-19";
    paths = [
      llvm.clang-unwrapped
      llvm.lld
      llvm.llvm
    ];
  };
  binaryen = pkgs.stdenv.mkDerivation {
    pname = "renpy-web-binaryen";
    version = "119";
    src = pkgs.fetchFromGitHub {
      owner = "WebAssembly";
      repo = "binaryen";
      rev = "version_119";
      hash = "sha256-JYXtN3CW4qm/nnjGRvv3GxQ0x9O9wHtNYQLqHIYTTOA=";
    };
    nativeBuildInputs = [
      pkgs.cmake
      pkgs.ninja
      pkgs.python3
    ];
    cmakeFlags = [
      "-DBUILD_TESTS=OFF"
      "-DENABLE_WERROR=OFF"
    ];
    # Backport the upstream fix for GCC 16's unused destructor instantiation.
    # https://github.com/WebAssembly/binaryen/commit/2ff34a2e8adfddc35c32cb0180eed22477fe0553
    patches = [ ./binaryen-gcc16.patch ];
    enableParallelBuilding = true;
    meta.license = pkgs.lib.licenses.asl20;
  };
  nodeModules = pkgs.buildNpmPackage {
    pname = "renpy-web-emscripten-node-modules";
    version = "3.1.67";
    src = source;
    npmDepsHash = "sha256-bqxUlxpIH1IAx9RbnaMq4dZW8fy+M/Q02Q7VrW/AKNQ=";
    dontNpmBuild = true;
    dontBuild = true;
    npmFlags = [ "--ignore-scripts" ];
    installPhase = ''
      mkdir -p "$out"
      cp -R node_modules "$out/"
    '';
  };

in
pkgs.stdenvNoCC.mkDerivation {
  pname = "renpy-web-emscripten";
  version = "3.1.67";
  src = source;
  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.python3
  ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/emscripten" "$out/bin"
    cp -R . "$out/share/emscripten"
    ln -s ${nodeModules}/node_modules "$out/share/emscripten/node_modules"
    cat > "$out/share/emscripten/.emscripten" <<CONFIG
    LLVM_ROOT = '${llvmEnv}/bin'
    BINARYEN_ROOT = '${binaryen}'
    NODE_JS = ['${pkgs.nodejs}/bin/node']
    CONFIG
    for tool in emcc em++ emar emranlib emstrip emconfigure emmake emcmake embuilder; do
      makeWrapper ${pkgs.python3}/bin/python3 "$out/bin/$tool" \
        --add-flags "$out/share/emscripten/$tool.py" \
        --set EM_CONFIG "$out/share/emscripten/.emscripten" \
        --set PYTHON ${pkgs.python3}/bin/python3 \
        --prefix PATH : ${
          pkgs.lib.makeBinPath [
            pkgs.nodejs
            llvmEnv
          ]
        }
    done
    makeWrapper ${llvmEnv}/bin/llvm-nm "$out/bin/emnm"
    runHook postInstall
  '';
  passthru = { inherit llvmEnv binaryen nodeModules; };
  meta = {
    description = "Pinned source-packaged Emscripten for Ren'Py Web";
    license = [
      pkgs.lib.licenses.mit
      pkgs.lib.licenses.ncsa
    ];
    platforms = pkgs.lib.platforms.linux;
  };
}
