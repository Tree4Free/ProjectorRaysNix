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

        # 🌟 FIX: Override mpg123 to disable live audio servers (PulseAudio/ALSA) 
        # which cannot be built statically on musl. ProjectorRays only needs decoding.
        mpg123StaticConfigured = staticPkgs.mpg123.override {
          withAudioModules = false;
        };
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
            mpg123StaticConfigured # 🌟 Use our customized, stripped-down audio decoder
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
