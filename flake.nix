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
            pkgs.git # 🌟 FIX 1: Provide native host git to resolve the Makefile version check
          ];
          
          buildInputs = with staticPkgs; [ 
            boost
            mpg123StaticConfigured
            zlib 
          ];

          # 🌟 FIX 2: Force include '-Isrc' so the compiler can locate local headers like 'director/castmember.h'
          NIX_CFLAGS_COMPILE = [ "-static" "-Isrc" ];
          NIX_LDFLAGS = [ "-static" ];

          # Pass the flags directly to Make as well
          makeFlags = [
            "LDFLAGS=-static"
            "CXXFLAGS=-static -Isrc" # 🌟 FIX 2 (Backup): Inject source paths into Make rules
          ];

          installPhase = ''
            mkdir -p $out/bin
            # The Makefile outputs a file named 'projectorrays' in the root directory
            cp projectorrays $out/bin/
          '';
        };
      }
    );
}
