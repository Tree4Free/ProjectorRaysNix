{
  description = "Completely static build of ProjectorRays";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        staticPkgs = pkgs.pkgsStatic;

        # 🌟 FIX: Manually strip out audio output modules by passing flags
        # directly to mpg123's configure script, avoiding function argument errors.
        mpg123StaticConfigured = staticPkgs.mpg123.overrideAttrs (oldAttrs: {
          configureFlags = (oldAttrs.configureFlags or []) ++ [
            "--with-audio=dummy"          # Completely drops live sound server drivers
            "--disable-lfs-alias"
          ];
          # Strip out dependencies that fail on static musl evaluation
          buildInputs = []; 
          propagatedBuildInputs = [];
        });
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
            mpg123StaticConfigured # Use our explicitly modified decoder
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
