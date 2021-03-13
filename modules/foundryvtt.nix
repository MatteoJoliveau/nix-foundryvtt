flakePackages: { config, lib, pkgs, ... }:

let
  cfg = config.services.foundryvtt;
  dataDir = "/var/lib/foundryvtt";
  configFile = pkgs.writeText "options.json"
    (builtins.toJSON (builtins.removeAttrs cfg [ "enable" "package" ]));
  foundryvtt = flakePackages.${pkgs.system}.foundryvtt;
in
{
  options = {
    services.foundryvtt = with lib; with lib.types; {
      enable = mkEnableOption ''
        Foundry Virtual Tabletop: A standalone application for online tabletop role-playing games.
      '';

      awsConfig = mkOption {
        type = nullOr str;
        default = null;
        description = ''
          A path to an AWS configuration file. This file is used to configure AWs connectivity for
          S3 assets and backups.
        '';
      };

      dataPath = mkOption {
        type = types.path;
        default = dataDir;
        description = ''
          The path where Foundry keeps its config, data, and logs.
        '';
      };

      hostname = mkOption {
        type = types.str;
        default = config.networking.hostname;
        description = ''
          A custom hostname to use in place of the host machine’s public IP address when displaying
          the address of the game session. This allows for reverse proxies or DNS servers to modify
          the public address.
        '';
      };

      port = mkOption {
        type = types.int;
        default = 30000;
        description = ''
          The port that Foundry bind to listen for connections.
        '';
      };

      language = mkOption {
        type = types.str;
        default = "en.core";
        description = ''
          The language module used by Foundry.
        '';
      };

      minifyStaticFiles = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If true, Foundry will serve minified JavaScript and CSS. Enabling this option reduces
          network traffic.
        '';
      };

      proxyPort = mkOption {
        type = nullOr int;
        default = null;
        description = ''
          The port on which the reverse proxy server is listening for connections. Foundry uses this
          to show the correct port in invitation links.
        '';
      };

      proxySSL = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Indicates that Foundry is running behind a reverse proxy that uses SSL. If true, Foundry
          will use “https” in invitation links and enable A/V functionality, which requires the
          server to be using SSL.
        '';
      };

      routePrefix = mkOption {
        type = str;
        default = "";
        description = ''
          A path that will be appended to the FQDN of the server.
        '';
      };

      sslCert = mkOption {
        type = nullOr path;
        default = null;
        description = ''
          A path to a SSL certificate that will be used by Foundry to serve over SSL.
        '';
      };

      sslKey = mkOption {
        type = nullOr path;
        default = null;
        description = ''
          A path to a SSL key file that will be used by Foundry to serve over SSL.
        '';
      };

      upnp = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Indicates whether UPnP should be used to set up uport forwarding.
        '';
      };

      package = mkOption {
        type = package;
        default = foundryvtt;
        description = ''
          The Foundry package to use with the service.
        '';
      };
    };
 };

  config = lib.mkIf cfg.enable {
    users.users.foundryvtt = {
      description = "Foundry VTT daemon user";
      isSystemUser = true;
      group = "foundryvtt";
    };

    users.groups.foundryvtt = {};

    systemd.services.foundryvtt = {
      description = "Foundry Virtual Tabletop";
      documentation = [ "https://foundryvtt.com/kb/" ];

      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "foundryvtt";
        Restart = "on-failure";
        ExecStart = ''
          ${cfg.package}/bin/foundryvtt --headless --noupdate --dataPath="${cfg.dataPath}"
        '';
        StateDirectory = "foundryvtt";
        StateDirectoryMode = "0755";
      };

      preStart = ''
        installedConfigFile="${dataDir}/Config/options.json"
        mkdir -p ${dataDir}/Config
        rm "$installedConfigFile" && cp ${configFile} "$installedConfigFile"
        chmod 0444 "$installedConfigFile"
      '';
    };
  };
}
