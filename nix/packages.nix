{ pkgs, baseRenpy, python ? pkgs.python312, extraPythonPackages ? null }:
let
  # Reuse nixpkgs' source builder. Its Python environments share one interpreter.
  configured = baseRenpy.override {
    python312 = python;
    withDoc = false;
    withDistributedLibs = false;
    withAarch64LinuxDistributedLibs = false;
  };
  nativeRuntime = configured.override { minimal = true; };
  # Extra packages are provided by an existing Python package set, not a resolver.
  pythonEnvironment = python.withPackages (if extraPythonPackages == null then (_: []) else extraPythonPackages);
  runtime = if extraPythonPackages == null then nativeRuntime else pkgs.symlinkJoin {
    name = "renpy-runtime-${nativeRuntime.version}";
    paths = [ nativeRuntime ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/renpy --prefix PYTHONPATH : ${pythonEnvironment}/${python.sitePackages}
    '';
    inherit (nativeRuntime) meta;
    passthru = { inherit nativeRuntime pythonEnvironment; };
  };
in {
  inherit runtime;
  sdk = configured.override { minimal = false; };
  source = nativeRuntime.src;
  inherit pythonEnvironment;
  mkProject = pkgs.callPackage ./mk-project.nix { renpy = runtime; };
  withPythonPackages = packages: import ./packages.nix {
    inherit pkgs baseRenpy python;
    extraPythonPackages = packages;
  };
}
