{ pkgs, lib, config, inputs, ... }:

let
  pkgs-stable = import inputs.nixpkgs-stable { system = pkgs.stdenv.system; };
  pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
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
    pkgs-stable.gnumake
  ];

  android = {
    enable = true;
    flutter.enable = true;
    flutter.package = pkgs-unstable.flutter;
  };

  scripts.hello.exec = ''
    figlet -w 120 $GREET | lolcat
  '';

  enterShell = ''
    hello
  '';

}

