{
  description = "A very basic flake";
  inputs =  {
    nixpkgs.url = "nixpkgs/8bdebd463bc77c9b83d66e690cba822a51c34b9b";
    timesketch_src = { url = "github:google/timesketch"; flake = false;};
  };
  outputs = inputs@{ self, nixpkgs, timesketch_src }: {
    overlay = final: prev: {
      timesketch = self.defaultPackage.x86_64-linux;
    };

    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux";};
      with python3.pkgs;
      let
        timesketch_dep = import ./env/python.nix {inherit pkgs;};
      in
        python3Packages.buildPythonPackage rec {
          pname = "timesketch";
          version = "pre${builtins.substring 0 8 (self.lastModifiedDate or self.lastModified)}_${self.shortRev or "dirty"}";
          src = timesketch_src;
          doCheck = false;
          propagatedBuildInputs = with python3Packages; [ timesketch_dep ];
        };
  };

}
