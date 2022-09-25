{ config, lib, pkgs, ... }: with lib;
let
  name = "gtchServer";
  pkg = gtchServer;
  cfg = config.services.${name};

  webSettings = {
    BASE_DIR = cfg.dataDir;
    STATIC_URL = cfg.dataDir + "/static/";
    STATIC_ROOT = cfg.dataDir + "/static/";
    DATABASES.default = {
      ENGINE = "django.db.backends.sqlite3";
      NAME = "${cfg.dataDir}/db.sqlite3";
    };
  } // cfg.webSettings;

  webSettingsJSON = pkgs.writeText "${name}-settings.json" (builtins.toJSON webSettings);

  environment = {
    SETTINGS_JSON = webSettingsJSON;
  } // cfg.environment;

  environmentFile = pkgs.writeText "${name}-env" (generators.toKeyValue { } environment);

  manageScript = with pkgs; (writeShellScriptBin "${name}-manage" ''
    export $(cat ${environmentFile} | xargs);

    sudo=""
    if [[ "$USER" != "${cfg.user}" ]]; then
        sudo="${sudo}/bin/sudo -u ${cfg.user} --preserve-env=${builtins.concatStringsSep "," (builtins.attrNames environment)}"
    fi

    $sudo ${pkg}/manage.py "$@"
  '');
in
{
  options.services.${name} = {

    enable = mkEnableOption name;

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address the server will listen on.";
    };

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port the server will listen on.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/${name}";
      description = "Directory to store ${name} database and other state/data files.";
    };

    user = mkOption {
      default = name;
      type = types.str;
      description = "User account under which ${name} runs.";
    };

    group = mkOption {
      default = name;
      type = types.str;
      description = "Group account under which ${name} runs.";
    };

    webSettings = mkOption {
      type = types.attrs;
      default = { };
      description = "Overrides for the default ${name} Django settings.";
    };

    environment = mkOption {
      type = types.attrs;
      default = { };
      description = "Defines environment variables.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ manageScript ];

    users.users.${cfg.user} = {
      description = "${name} service owner.";
      group = cfg.user;
      isSystemUser = true;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    systemd.services.${name} = {
      description = "${name} Service";
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        ${pkg}/manage.py migrate --noinput
        ${pkg}/manage.py collectstatic --noinput
      '';

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        EnvironmentFile = environmentFile;

        ExecStart = ''
          ${pkg}/manage.py runserver ${cfg.listenAddress}:${toString cfg.port}
        '';

        WorkingDirectory = cfg.dataDir;
      };
    };
  };
}
