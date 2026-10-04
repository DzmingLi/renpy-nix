{ lib, configured }:
# Keep nixpkgs' source pin, patches, dependency lookup and native build inputs.
# Only the costly Cython/C compilation moves into this reusable derivation.
configured.overrideAttrs (old: {
  pname = "renpy-native-extensions";
  buildPhase = ''
    runHook preBuild
    ./setup.py build_ext --inplace -j $NIX_BUILD_CORES
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/renpy"
    while IFS= read -r -d "" module; do
      install -Dm755 "$module" "$out/share/renpy/$module"
    done < <(find . -type f -name '*.so' ! -path './build/*' -print0)
    test -n "$(find "$out/share/renpy" -name '*.so' -print -quit)"
    runHook postInstall
  '';
  # There is no executable until this component is combined with Python sources.
  meta = builtins.removeAttrs old.meta [ "mainProgram" ];
})
