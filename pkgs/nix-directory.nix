# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, stdenv, closureInfo, prootTermux, proot, qemuAarch64Static }:

let
  buildRootDirectory = "root-directory";

  prootCommand = lib.concatStringsSep " " [
    "${proot}/bin/proot"
    (
      if config.build.arch == "aarch64"
      then "-q ${qemuAarch64Static}/bin/qemu-aarch64-static"
      else "-b /dev"
    )
    "-r ${buildRootDirectory}"
    "-w /"
  ];

  prootTermuxClosure = closureInfo {
    rootPaths = [
      prootTermux
    ];
  };
in

stdenv.mkDerivation {
  name = "nix-directory";

  src = builtins.fetchurl {
    url = "https://nixos.org/releases/nix/nix-2.3.13/nix-2.3.13-${config.build.arch}-linux.tar.xz";
    sha256 =
      let
        archShas = {
         aarch64 = "1hl6pd02nssscn32mrndif2fxfssxiarrpjvqyjicwnz6yn9mhpq";
         i686 = "0249sbmgmi7cah099wywlqx3ygwpjgl6vcyivqix9rwpnpap417x";
        };
      in
        "${archShas.${config.build.arch}}";
  };

  PROOT_NO_SECCOMP = 1;  # see https://github.com/proot-me/PRoot/issues/106

  buildPhase = ''
    mkdir --parents ${buildRootDirectory}/nix
    cp --recursive store ${buildRootDirectory}/nix/store

    CACERT=$(find ${buildRootDirectory}/nix/store -path '*-nss-cacert-*/ca-bundle.crt' | sed 's,^${buildRootDirectory},,')
    PKG_BASH=$(find ${buildRootDirectory}/nix/store -path '*/bin/bash' | sed 's,^${buildRootDirectory},,')
    PKG_BASH=''${PKG_BASH%/bin/bash}
    PKG_COREUTILS=$(find ${buildRootDirectory}/nix/store -path '*/bin/env' | sed 's,^${buildRootDirectory},,')
    PKG_COREUTILS=''${PKG_COREUTILS%/bin/env}
    PKG_NIX=$(find ${buildRootDirectory}/nix/store -path '*/bin/nix' | sed 's,^${buildRootDirectory},,')
    PKG_NIX=''${PKG_NIX%/bin/nix}

    for i in $(< ${prootTermuxClosure}/store-paths); do
      cp --archive "$i" "${buildRootDirectory}$i"
    done

    USER=${config.user.userName} ${prootCommand} "$PKG_NIX/bin/nix-store" --init
    USER=${config.user.userName} ${prootCommand} "$PKG_NIX/bin/nix-store" --load-db < .reginfo
    USER=${config.user.userName} ${prootCommand} "$PKG_NIX/bin/nix-store" --load-db < ${prootTermuxClosure}/registration

    cat > package-info.nix <<EOF
    {
      bash = "$PKG_BASH";
      cacert = "$CACERT";
      coreutils = "$PKG_COREUTILS";
      nix = "$PKG_NIX";
    }
    EOF
  '';

  installPhase = ''
    mkdir $out
    cp --recursive ${buildRootDirectory}/nix/store $out/store
    cp --recursive ${buildRootDirectory}/nix/var $out/var
    install -D -m 0644 package-info.nix $out/nix-support/package-info.nix
  '';

  fixupPhase = "true";
}
