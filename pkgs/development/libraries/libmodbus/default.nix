{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "libmodbus-3.1.6";

  src = fetchurl {
    url = "http://libmodbus.org/releases/${name}.tar.gz";
    sha256 = "05kwz0n5gn9m33cflzv87lz3zp502yp8fpfzbx70knvfl6agmnfp";
  };

  meta = with stdenv.lib; {
    description = "Library to send/receive data according to the Modbus protocol";
    homepage = https://libmodbus.org/;
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}
