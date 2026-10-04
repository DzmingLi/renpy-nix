{
  description = "Nix-native Ren'Py components and project builders";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/0dad76d31d59d0f9e1e6b2404dd28044bba50a6d";
  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem = nixpkgs.lib.genAttrs systems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
    in
    {
      formatter = eachSystem (system: (pkgsFor system).nixfmt-tree);
      overlays.default = import ./nix/overlay.nix;
      lib.mkRenpyProject = pkgs: pkgs.mkRenpyProject;
      packages = eachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.renpyPackages.runtime;
          inherit (pkgs.renpyPackages) runtime sdk;
          native-extensions = pkgs.renpyPackages.components.nativeExtensions;
          web-toolchain = pkgs.renpyPackages.web.toolchain;
          web-zlib = pkgs.renpyPackages.web.libraries.zlib;
          web-bzip2 = pkgs.renpyPackages.web.libraries.bzip2;
          web-xz = pkgs.renpyPackages.web.libraries.xz;
          web-python = pkgs.renpyPackages.web.python;
          hello = pkgs.mkRenpyProject {
            pname = "renpy-hello";
            version = "0.1.0";
            src = ./examples/hello;
          };
        }
      );
      apps = eachSystem (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.hello}/bin/renpy-hello";
        };
      });
      checks = eachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          project = pkgs.runCommand "renpy-project-smoke" { } ''
            test -f ${self.packages.${system}.hello}/share/renpy-hello/game/script.rpyc
            test -f ${self.packages.${system}.hello}/share/renpy-hello/lint.txt
            export HOME=$TMPDIR
            ${self.packages.${system}.hello}/bin/renpy-hello --version
            touch $out
          '';
          python-packages = (pkgs.renpyPackages.withPythonPackages (ps: [ ps.pillow ])).mkProject {
            pname = "renpy-python-check";
            src = ./tests/python-project;
          };
          sdk = pkgs.runCommand "renpy-sdk-check" { nativeBuildInputs = [ pkgs.renpyPackages.sdk ]; } ''
            export HOME=$TMPDIR/home SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy
            mkdir -p "$HOME"
            renpy-launcher --version
            test -f ${pkgs.renpyPackages.sdk}/share/renpy/launcher/game/updater.rpyc
            grep -F 'return []' ${pkgs.renpyPackages.sdk}/share/renpy/launcher/game/updater.rpy
            touch "$out"
          '';
          runtime =
            pkgs.runCommand "renpy-runtime-smoke" { nativeBuildInputs = [ pkgs.renpyPackages.runtime ]; }
              ''
                export HOME=$TMPDIR
                renpy --version > version.txt
                grep -F "${pkgs.renpyPackages.runtime.passthru.appver}" version.txt
                touch $out
              '';
          invalid-project = pkgs.runCommand "renpy-builder-contract" { } ''
            test '${
              if
                (builtins.tryEval (
                  pkgs.mkRenpyProject {
                    pname = "invalid/name";
                    src = ./examples/hello;
                  }
                )).success
              then
                "accepted"
              else
                "rejected"
            }' = rejected
            touch $out
          '';
        }
        // import ./nix/web/checks.nix {
          inherit pkgs;
          web = pkgs.renpyPackages.web;
        }
      );
      devShells = eachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.renpyPackages.runtime
              pkgs.nixfmt
            ];
          };
        }
      );
    };
}
