{
  description = "Nix-native Ren'Py components and project builders";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/0dad76d31d59d0f9e1e6b2404dd28044bba50a6d";
  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      eachSystem = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
    in {
      overlays.default = import ./nix/overlay.nix;
      lib.mkRenpyProject = pkgs: pkgs.mkRenpyProject;
      packages = eachSystem (system: let pkgs = pkgsFor system; in {
        default = pkgs.renpyPackages.runtime;
        inherit (pkgs.renpyPackages) runtime sdk;
        hello = pkgs.mkRenpyProject { pname = "renpy-hello"; version = "0.1.0"; src = ./examples/hello; };
      });
      apps = eachSystem (system: {
        default = { type = "app"; program = "${self.packages.${system}.hello}/bin/renpy-hello"; };
      });
      checks = eachSystem (system: let pkgs = pkgsFor system; in {
        project = pkgs.runCommand "renpy-project-smoke" {} ''
          test -f ${self.packages.${system}.hello}/share/renpy-hello/game/script.rpyc
          test -f ${self.packages.${system}.hello}/share/renpy-hello/lint.txt
          export HOME=$TMPDIR
          ${self.packages.${system}.hello}/bin/renpy-hello --version
          touch $out
        '';
        runtime = pkgs.runCommand "renpy-runtime-smoke" { nativeBuildInputs = [ pkgs.renpyPackages.runtime ]; } ''
          export HOME=$TMPDIR
          renpy --version > version.txt
          grep -F "${pkgs.renpyPackages.runtime.passthru.appver}" version.txt
          touch $out
        '';
        invalid-project = pkgs.runCommand "renpy-builder-contract" {} ''
          test '${if (builtins.tryEval (pkgs.mkRenpyProject { pname = "invalid/name"; src = ./examples/hello; })).success then "accepted" else "rejected"}' = rejected
          touch $out
        '';
      });
      devShells = eachSystem (system: let pkgs = pkgsFor system; in {
        default = pkgs.mkShell { packages = [ pkgs.renpyPackages.runtime pkgs.nixfmt ]; };
      });
    };
}
