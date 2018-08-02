{ stdenv, automake, autoconf, pkgconfig, fetchgit,
  libtool, glib, dbus, libudev, mobile-broadband-provider-info }:

let
  version = "1.24";
in
stdenv.mkDerivation {
  name = "ofono-${version}";
  inherit version;

  nativeBuildInputs = [
    automake
    autoconf
    pkgconfig
  ];

  buildInputs = [
    libtool
    glib
    dbus
    libudev
    mobile-broadband-provider-info
  ];

  src = fetchgit {
    url = git://git.kernel.org/pub/scm/network/ofono/ofono.git;
    rev = version;
    sha256 = "1i668ry4zfi3x3zcwigzivs2cp452j6lajf6xk76nkma8d8r037j";
  };

  preConfigure = "echo $out;  ./bootstrap";
  configureFlags = [
    "--sysconfdir=${placeholder "out"}/etc"
    "--datadir=${placeholder "out"}/etc"
    "--with-dbusconfdir=${placeholder "out"}/etc"
    "--with-dbusdatadir=${placeholder "out"}/etc"
    "--with-systemdunitdir=${placeholder "out"}/lib/systemd/system"
  ];
}
