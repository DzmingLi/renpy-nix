{
  pkgs,
  baseRenpy,
  python ? pkgs.python312,
  extraPythonPackages ? null,
}:
let
  # Reuse nixpkgs' source builder. Its Python environments share one interpreter.
  configured = baseRenpy.override {
    python312 = python;
    withDoc = false;
    withDistributedLibs = false;
    withAarch64LinuxDistributedLibs = false;
  };
  nativeExtensions = pkgs.callPackage ./components/native-extensions.nix {
    configured = configured.override { minimal = true; };
  };
  reuseExtensions =
    package:
    package.overrideAttrs (old: {
      buildPhase =
        assert pkgs.lib.assertMsg (
          pkgs.lib.hasInfix "./setup.py build_ext --inplace -j $NIX_BUILD_CORES" old.buildPhase
          && pkgs.lib.hasInfix "./setup.py install_lib -d $out/share/renpy" old.installPhase
        ) "nixpkgs Ren'Py build phases changed; update the native component adapter";
        ''
          export HOME=$TMPDIR/home SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy
          mkdir -p "$HOME"
        ''
        +
          builtins.replaceStrings
            [ "./setup.py build_ext --inplace -j $NIX_BUILD_CORES" ]
            [ "cp -rs ${nativeExtensions}/share/renpy/. ." ]
            old.buildPhase;
      installPhase =
        builtins.replaceStrings
          [ "./setup.py install_lib -d $out/share/renpy" ]
          [
            ''
              mkdir -p "$out/share/renpy"
              cp -a ${nativeExtensions}/share/renpy/*.so "$out/share/renpy/"
            ''
          ]
          old.installPhase;
    });
  nativeRuntime = reuseExtensions (configured.override { minimal = true; });
  # Extra packages are provided by an existing Python package set, not a resolver.
  pythonEnvironment = python.withPackages (
    if extraPythonPackages == null then (_: [ ]) else extraPythonPackages
  );
  runtime =
    if extraPythonPackages == null then
      nativeRuntime
    else
      pkgs.symlinkJoin {
        name = "renpy-runtime-${nativeRuntime.version}";
        paths = [ nativeRuntime ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/renpy --prefix PYTHONPATH : ${pythonEnvironment}/${python.sitePackages}
        '';
        inherit (nativeRuntime) meta;
        passthru = nativeRuntime.passthru // {
          inherit nativeRuntime pythonEnvironment;
        };
      };
in
{
  inherit runtime;
  sdk = (reuseExtensions (configured.override { minimal = false; })).overrideAttrs (old: {
    postPatch = old.postPatch + ''
      python ${./components/immutable-launcher.py}
    '';
    buildPhase = old.buildPhase + ''
      python renpy.py launcher compile
    '';
  });
  components = {
    inherit nativeExtensions;
    inherit runtime;
  };
  sources = {
    engine = nativeRuntime.src;
    build = import ./sources.nix { inherit pkgs; };
  };
  web = import ./web { inherit pkgs; };
  source = nativeRuntime.src;
  inherit pythonEnvironment;
  mkProject = pkgs.callPackage ./mk-project.nix { renpy = runtime; };
  withPythonPackages =
    packages:
    import ./packages.nix {
      inherit pkgs baseRenpy python;
      extraPythonPackages = packages;
    };
}
