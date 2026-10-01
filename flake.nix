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

          w = wrappers.wrapperModules.mpv.apply {
            inherit pkgs;

            /*
              Everything in your config that mpv should see as an
              ordinary config file goes here.
            */

            "mpv.conf".source = ./mpv.conf;
            "input.conf".source = ./input.conf;

            /*
              mpv scripts.

              These are copied into the wrapper's script directory
              and loaded by mpv.
            */
            scripts = [
              ./scripts/chapterskip.lua
              ./scripts/clock.lua
              ./scripts/cut_sub.lua
              ./scripts/dir_subs.lua
              ./scripts/embedded-lyrics.lua
              ./scripts/extract_fonts.lua
              ./scripts/music-reset.lua
              ./scripts/playlistmanager.lua
              ./scripts/skip_sponsorblock.lua
              ./scripts/speed_manager.lua
              ./scripts/sub_export.lua
              ./scripts/sub-fastwhisper.lua
              ./scripts/uosc_history.lua
              ./scripts/uosc_webdav.lua
              ./scripts/winisland.lua

              ./scripts/uosc/main.lua
              ./scripts/uosc_danmaku/main.lua
              ./scripts/uosc_history/main.lua
              ./scripts/uosc_webdav/main.lua
            ];

            /*
              Extra files used by the scripts.

              These are installed into the mpv config directory so
              paths such as:
                  ~~ /script-opts/foo.conf
                  ~~ /script-modules/...
              continue to work.
            */
            extraFiles = {
              "script-opts" = ./script-opts;
              "script-modules" = ./script-modules;
              "fonts" = ./fonts;

              /*
                uosc has data files which are referenced relative to
                its own script directory.
              */
              "scripts/uosc/char-conv" = ./scripts/uosc/char-conv;
              "scripts/uosc/intl" = ./scripts/uosc/intl;
              "scripts/uosc/elements" = ./scripts/uosc/elements;
              "scripts/uosc/lib" = ./scripts/uosc/lib;

              "scripts/uosc_danmaku/apis" = ./scripts/uosc_danmaku/apis;
              "scripts/uosc_danmaku/dicts" = ./scripts/uosc_danmaku/dicts;
              "scripts/uosc_danmaku/modules" = ./scripts/uosc_danmaku/modules;

              "scripts/uosc_history/i18n" = ./scripts/uosc_history/i18n;
              "scripts/uosc_history/menus" = ./scripts/uosc_history/menus;

              "scripts/uosc_webdav/modules" = ./scripts/uosc_webdav/modules;

              /*
                Optional JSON/state files that appear to be part of
                the uosc history setup.

                Remove these if they are meant to be machine-local
                state rather than shipped configuration.
              */
              "uosc_history_bookmarks.json" = ./uosc_history_bookmarks.json;
              "uosc_history.json" = ./uosc_history.json;
            };

            /*
              Runtime dependencies.

              yt-dlp is what mpv's ytdl_hook invokes for URLs such
              as YouTube/Twitch/etc.
            */
            runtimePackages = [
              pkgs.yt-dlp
              pkgs.ffmpeg

              /*
                Useful if any of your scripts/download workflows use it.
                Remove if unnecessary.
              */
              pkgs.aria2
            ];
          };
        in
          w.wrapper;

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
