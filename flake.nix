{
  description = "My mpv configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkMpv = system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          mpvConfig = pkgs.stdenvNoCC.mkDerivation {
            pname = "mpv-config";
            version = "unstable";

            src = ./.;

            dontBuild = true;

            installPhase = ''
              mkdir -p $out

              cp mpv.conf $out/mpv.conf
              cp input.conf $out/input.conf

              cp -r scripts $out/scripts
              cp -r script-opts $out/script-opts
              cp -r script-modules $out/script-modules
              cp -r fonts $out/fonts
            '';
          };

        in
          pkgs.symlinkJoin {
            name = "mpv-with-config";

            paths = [
              pkgs.mpv
            ];

            nativeBuildInputs = [
              pkgs.makeWrapper
            ];

            postBuild = ''
              wrapProgram $out/bin/mpv \
                --add-flags "--config-dir=${mpvConfig}" \
                --prefix PATH : ${
                  pkgs.lib.makeBinPath [
                    pkgs.yt-dlp
                    pkgs.ffmpeg
                  ]
                }
            '';
          };

    in
    {
      packages = forAllSystems (system: {
        default = mkMpv system;
        mpv = mkMpv system;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${mkMpv system}/bin/mpv";
        };
      });
    };
}
