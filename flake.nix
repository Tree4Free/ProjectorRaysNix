{
  description = "Completely static build of ProjectorRays";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # 🌟 FIX: Inject the mpg123 modification cleanly inside the global Nix config context
        pkgs = import nixpkgs {
          inherit system;
          config = {
            packageOverrides = super: {
              mpg123 = super.mpg123.override {
                withAudioModules = false;
              };
            };
          };
        };

        # This now extracts a perfectly configured, non-breaking static package set
        staticPkgs = pkgs.pkgsStatic;
      in
      {
        packages.default = staticPkgs.stdenv.mkDerivation {
          pname = "projectorrays";
          version = "git-latest";

          src = ./.;

          nativeBuildInputs = with staticPkgs; [ 
            gnumake 
            pkg-config 
          ];
          
          buildInputs = with staticPkgs; [ 
            boost
            mpg123 # 🌟 Automatically evaluates with audio modules disabled!
            zlib 
          ];

          makeFlags = [
            "LDFLAGS=-static"
            "CXXFLAGS=-static"
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp projectorrays $out/bin/
          '';
        };
      }
    );
}
