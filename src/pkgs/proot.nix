# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ pinnedPkgs, crossStaticPkgs, talloc }:

crossStaticPkgs.stdenv.mkDerivation rec {
  pname = "proot-termux";
  version = "unstable-2019-09-05";

  src = pinnedPkgs.fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "3ea655b1ae40bfa2ee612d45bf1e7ad97c4559f8";
    sha256 = "05y30ifbp4sn1pzy8wlifc5d9n2lrgspqzdjix1kxjj9j9947qgd";
  };

  buildInputs = [ talloc ];

  makeFlags = [ "-Csrc CFLAGS=-D__ANDROID__" ];

  installPhase = ''
    install -D -m 0755 src/proot $out/bin/proot-static
  '';
}
