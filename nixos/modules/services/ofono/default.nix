{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ofono;
in
{
  options = {
    services.ofono = {
      enable = mkEnableOption "Telephony service";

      plugins.phonesim = {
        enable = mkEnableOption "phonesim plugin";

        port = mkOption {
          default = 12345;
          type = types.number;
          description = "phonesim port";
        };

        address = mkOption {
          default = "127.0.0.1";
          type = types.str;
          description = "phonesim port";
        };

        driver = mkOption {
          default = "phonesim";
          type = types.str;
          description = "phonesim driver";
        };
      };
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.ofono = {
      wantedBy = [ "multi-user.target" ];
      after = [ "syslog.target" ];
      description = "Telephony service";

      serviceConfig = {
        Type = "dbus";
        BusName = "org.ofono";
        StandardError = null;
        ExecStart = "${pkgs.ofono}/bin/ofonod -n";
      };
    };

    services.dbus.packages = [ pkgs.ofono ];

    environment.etc."ofono/phonesim.conf" = {
      enable = cfg.plugins.phonesim.enable;
      text = ''
        [phonesim]
        Driver=${cfg.plugins.phonesim.driver}
        Address=${cfg.plugins.phonesim.address}
        Port=${toString cfg.plugins.phonesim.port}
      '';
    };
  };
}
