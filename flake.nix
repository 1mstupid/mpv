{
  description = "My mpv configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    wrappers.url = "github:Lassulus/wrappers";
  };

  outputs = { self, nixpkgs, wrappers }:
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

          /*
            Build the complete mpv config directory.

            This preserves the exact directory structure that your
            existing mpv configuration expects.
          */
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

          /*
            A wrapper-specific mpv.conf.

            The normal mpv.conf remains untouched. This file simply
            includes it and tells mpv where the Nix-provided scripts
            and modules live.
          */
          wrapperConfig = pkgs.writeText "mpv-wrapper.conf" ''
            include=${mpvConfig}/mpv.conf

            # Nix-provided script locations
            script=${mpvConfig}/scripts/uosc/main.lua
            script=${mpvConfig}/scripts/uosc_history.lua
            script=${mpvConfig}/scripts/uosc_danmaku/main.lua
            script=${mpvConfig}/scripts/uosc_webdav.lua
          '';

          wrappedMpv =
            wrappers.wrapperModules.mpv.apply {
              inherit pkgs;

              "mpv.conf".path = wrapperConfig;
              "input.conf".path = "${mpvConfig}/input.conf";

              extraPackages = [
                pkgs.yt-dlp
                pkgs.ffmpeg
              ];
            };

        in
          wrappedMpv.wrapper;

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
