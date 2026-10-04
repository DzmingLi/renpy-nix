{ lib, stdenvNoCC, makeWrapper, renpy }:
{ pname, version ? "0.1.0", src, projectSubdir ? ".", lint ? true, meta ? {}, ... }@args:
assert lib.assertMsg (builtins.match "[a-zA-Z0-9][a-zA-Z0-9._+-]*" pname != null) "pname must be a safe executable name";
assert lib.assertMsg (builtins.match "[a-zA-Z0-9._/-]+" projectSubdir != null && !(lib.hasPrefix "/" projectSubdir) && !(builtins.elem ".." (lib.splitString "/" projectSubdir))) "projectSubdir must stay within src";
stdenvNoCC.mkDerivation ((builtins.removeAttrs args [ "projectSubdir" "lint" "meta" ]) // {
  inherit pname version src;
  strictDeps = true;
  nativeBuildInputs = [ makeWrapper renpy ];
  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR/home
    mkdir -p "$HOME"
    export SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy
    cd ${lib.escapeShellArg projectSubdir}
    test -d game || { echo "Expected a normal Ren'Py project with game/" >&2; exit 1; }
    renpy "$PWD" compile
    ${lib.optionalString lint ''renpy "$PWD" lint > "$TMPDIR/lint.txt"''}
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/${pname}" "$out/bin"
    cp -R game "$out/share/${pname}/game"
    rm -rf "$out/share/${pname}/game/saves"
    ${lib.optionalString lint ''cp "$TMPDIR/lint.txt" "$out/share/${pname}/lint.txt"''}
    makeWrapper ${lib.getExe renpy} "$out/bin/${pname}" --add-flags "$out/share/${pname}"
    runHook postInstall
  '';
  meta = { description = "Ren'Py project ${pname}"; platforms = lib.platforms.linux; mainProgram = pname; } // meta;
})
