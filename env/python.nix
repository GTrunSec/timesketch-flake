{ pkgs }:
let
  python = pkgs.python37;
  result = import ./machnix.nix { inherit pkgs python; };
  manylinux1 = pkgs.pythonManylinuxPackages.manylinux1;
  overrides = result.overrides manylinux1 pkgs.autoPatchelfHook;
  py = python.override { packageOverrides = overrides; };
in
py.withPackages (ps: result.select_pkgs ps)
