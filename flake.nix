{
  description = "Completely static build of ProjectorRays";

  inputs = {
    # Pin to a highly stable, recent Nixpkgs release
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # pkgsStatic forces the entire compiler and all libraries to be 100% static
        pkgs = import nixpkgs { inherit system; };
        staticPkgs = pkgs.pkgsStatic;
      in
      {
        packages.default = staticPkgs.stdenv.mkDerivation {
          pname = "projectorrays";
          version = "git-latest";

          # Points to the local project files
          src = ./.;

          # Core tools required by the host system to run the build
          nativeBuildInputs = with staticPkgs; [ 
            gnumake 
            pkg-config 
          ];
          
          # The exact static dependencies requested by ProjectorRays
          buildInputs = with staticPkgs; [ 
            boost
            mpg123
            zlib 
          ];

          # We override the Makefile flags to force static binary compilation
          makeFlags = [
            "LDFLAGS=-static"
            "CXXFLAGS=-static"
          ];

          # Tell Nix exactly where to put the resulting binary
          installPhase = ''
            mkdir -p $out/bin
            cp projectorrays $out/bin/
          '';
        };
      }
    );
}
