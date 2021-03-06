# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs, isFlake }:

[
  ./build/activation.nix
  ./build/config.nix
  ./environment/ca.nix
  ./environment/etc
  ./environment/links.nix
  ./environment/login
  ./environment/networking.nix
  ./environment/nix.nix
  ./environment/path.nix
  ./environment/session-init.nix
  ./home-manager.nix
  ./time.nix
  ./user.nix
  ./version.nix
  ./workaround-make.nix
  (pkgs.path + "/nixos/modules/misc/assertions.nix")
] ++ pkgs.lib.optionals (!isFlake) [ ./nixpkgs.nix ]
