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

        # Strip audio output modules directly from the configure engine
        mpg123StaticConfigured = staticPkgs.mpg123.overrideAttrs (oldAttrs: {
          configureFlags = (oldAttrs.configureFlags or []) ++ [
            "--with-audio=dummy"
            "--disable-lfs-alias"
          ];
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
            pkgs.git
            staticPkgs.xxd # 🌟 FIX: Inject the tool needed to process fontmap hex grids!
          ];
          
          buildInputs = with staticPkgs; [ 
            boost
            mpg123StaticConfigured
            zlib 
          ];

          # Force include '-Isrc' so the compiler can locate local headers
          NIX_CFLAGS_COMPILE = [ "-static" "-Isrc" ];
          NIX_LDFLAGS = [ "-static" ];

          makeFlags = [
            "LDFLAGS=-static"
            "CXXFLAGS=-static -Isrc"
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp projectorrays $out/bin/
          '';
        };
      }
    );
}
