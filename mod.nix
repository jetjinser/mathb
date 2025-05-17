{
  lib,
  pkgs,
  config,
  ...
}:

let
  defaultUser = "mathb";
  cfg = config.services.mathb;
in
with lib;
{
  options.services.mathb = {
    enable = mkEnableOption "Whether to enable mathb";
    live-package = mkOption {
      type = types.package;
      default = pkgs.mathb-live;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.mathb;
    };

    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = "User account under which mathb runs.";
    };
    group = mkOption {
      type = types.str;
      default = defaultUser;
      description = "Group under which mathb runs.";
    };

    port = mkOption {
      type = types.port;
      default = 4242;
      description = "The mathb port number.";
      readOnly = true;
    };

    environment = mkOption {
      type = types.lazyAttrsOf types.str;
      default = {
        MB_DATA_DIRECTORY = "/var/lib/mathb/";
        MB_LOG_DIRECTORY = "/var/log/mathb/";
        MB_DIST_DIRECTORY = "${cfg.package}/dist/";
      };
      description = "The environments.";
      readOnly = true; # TBD
    };

    openFirewall = lib.mkEnableOption "Open ports in the firewall for mathb.";
  };

  config = mkIf cfg.enable {
    users.users = mkIf (cfg.user == defaultUser) {
      ${defaultUser} = {
        inherit (cfg) group;
        isSystemUser = true;
      };
    };
    users.groups = mkIf (cfg.group == defaultUser) {
      ${defaultUser} = { };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.mathb = {
      description = "mathb service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      inherit (cfg) environment;

      serviceConfig =
        let
          setup-meta = pkgs.writeShellScript "setup-meta" ''
            cp -r ${cfg.package}/meta/data/* ${cfg.environment.MB_DATA_DIRECTORY}
            chown -R mathb:mathb ${cfg.environment.MB_DATA_DIRECTORY}
            find ${cfg.environment.MB_DATA_DIRECTORY} -type d -exec chmod 750 {} \;
            find ${cfg.environment.MB_DATA_DIRECTORY} -type f -exec chmod 640 {} \;
          '';
        in
        {
          ExecStartPre = "-${setup-meta}";
          ExecStart = lib.getExe' cfg.live-package "mathb-live";
          StateDirectory = "mathb";
          RuntimeDirectory = "mathb";
          LogsDirectory = "mathb";
          Restart = "on-failure";
          WorkingDirectory = "/var/lib/mathb";

          User = cfg.user;
          Group = cfg.group;
        };
    };
  };
}
