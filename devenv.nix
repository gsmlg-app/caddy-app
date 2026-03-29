{ pkgs, lib, config, inputs, ... }:

let
  pkgs-stable = import inputs.nixpkgs-stable { system = pkgs.stdenv.system; config = { allowUnfree = true; android_sdk.accept_license = true; }; };
  pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; config = { allowUnfree = true; android_sdk.accept_license = true; }; };
in
{
  env.GREET = "Caddy App";

  env.GOPATH = "${config.devenv.root}/.devenv/go";

  packages = [
    pkgs-stable.git
    pkgs-stable.figlet
    pkgs-stable.lolcat
    pkgs-stable.watchman
    pkgs-stable.inotify-tools
    pkgs-stable.go
    pkgs-stable.gomobile
    pkgs-stable.xcaddy
    pkgs-stable.gnumake
    pkgs.pkg-config
    pkgs.libsecret
  ];

  android = {
    enable = true;
    flutter.enable = true;
    flutter.package = pkgs-unstable.flutter;
    android-studio.enable = false;
    extraLicenses = [
      "android-sdk-license"
      "android-sdk-preview-license"
    ];
  };

  scripts.hello.exec = ''
    figlet -w 120 $GREET | lolcat
  '';

  scripts.build-caddy-bridge.exec = ''
    echo "Building Caddy bridge..."
    export GOPATH="''${GOPATH:-$HOME/go}"
    cd go/caddy_bridge && make linux && echo "Caddy bridge built successfully." || echo "Caddy bridge build failed!"
  '';

  enterShell = ''
    hello
  '';

}

