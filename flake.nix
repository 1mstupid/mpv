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

          wrappedMpv =
            wrappers.wrapperModules.mpv.apply {
              inherit pkgs;

              # Base mpv configuration.
              "mpv.conf".source = "${mpvConfig}/mpv.conf";
              "input.conf".source = "${mpvConfig}/input.conf";

              # Executables available to mpv and its scripts.
              extraPackages = [
                pkgs.yt-dlp
                pkgs.ffmpeg
              ];

              # Add the rest of your config to the wrapper.
              extend = {
                postBuild = ''
                  cp -r ${mpvConfig}/scripts "$out/share/mpv/scripts"
                  cp -r ${mpvConfig}/script-opts "$out/share/mpv/script-opts"
                  cp -r ${mpvConfig}/script-modules "$out/share/mpv/script-modules"
                  cp -r ${mpvConfig}/fonts "$out/share/mpv/fonts"
                '';
              };
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
