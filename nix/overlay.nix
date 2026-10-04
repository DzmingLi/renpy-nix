final: prev: {
  renpyPackages = import ./packages.nix {
    pkgs = final;
    baseRenpy = prev.renpy;
  };
  mkRenpyProject = final.renpyPackages.mkProject;
}
