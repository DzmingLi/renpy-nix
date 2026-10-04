{ pkgs, web }:
{
  web-compression =
    pkgs.runCommand "renpy-web-compression-check"
      {
        nativeBuildInputs = [
          web.toolchain
          pkgs.nodejs
        ];
      }
      ''
        export HOME=$TMPDIR/home EM_CACHE=$TMPDIR/emscripten-cache
        mkdir -p "$HOME" "$EM_CACHE"
        emcc ${../../tests/web-compression.c} -O2 \
          -I${web.libraries.zlib}/include -I${web.libraries.bzip2}/include -I${web.libraries.xz}/include \
          ${web.libraries.zlib}/lib/libz.a ${web.libraries.bzip2}/lib/libbz2.a ${web.libraries.xz}/lib/liblzma.a \
          -sENVIRONMENT=node -sWASM_ASYNC_COMPILATION=0 -o roundtrip.js
        node roundtrip.js
        mkdir -p "$out"
        cp roundtrip.js roundtrip.wasm "$out/"
      '';
  web-python-artifacts =
    pkgs.runCommand "renpy-web-python-artifacts" { nativeBuildInputs = [ web.toolchain ]; }
      ''
        test -f ${web.python}/lib/libpython3.12.a
        emar p ${web.python}/lib/libpython3.12.a getcompiler.o > core.o
        test "$(od -An -tx1 -N4 core.o | tr -d ' \n')" = 0061736d
        test -f ${web.python}/include/python3.12/Python.h
        test -f ${web.python}/lib/python3.12/os.py
        touch "$out"
      '';
}
