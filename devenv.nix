{ pkgs, lib, config, inputs, ... }:

let
  pkgs-stable = import inputs.nixpkgs-stable { system = pkgs.stdenv.system; config = { allowUnfree = true; android_sdk.accept_license = true; }; };
  pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; config = { allowUnfree = true; android_sdk.accept_license = true; }; };
in
{
  env.GREET = "Caddy App";

  env.GOPATH = "${builtins.getEnv "HOME"}/go";

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

  enterShell = ''
    hello
  '';

}

