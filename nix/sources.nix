{ pkgs }:
pkgs.fetchFromGitHub {
  owner = "renpy";
  repo = "renpy-build";
  rev = "7bfab40c1174f622f644b24669afd5fb167fbb79";
  hash = "sha256-ZtF5HLaAhT+2Dm2gWKqzbx98V6sTPJZ8EVPwXJBR/lk=";
}
