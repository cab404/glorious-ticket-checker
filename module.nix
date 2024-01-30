input: { config, lib, pkgs, ... }: with lib;
let
  name = "gtch";
  pkg = input.packages."${pkgs.system}".default;
  staticFiles = input.packages."${pkgs.system}".static;
  cfg = config.services.${name};

  webSettings = {
    DEBUG = false;
    BASE_DIR = cfg.dataDir;
    STATIC_URL = staticFiles;
    STATIC_ROOT = "/";
    DATABASES.default = {
      ENGINE = "django.db.backends.sqlite3";
      NAME = "${cfg.dataDir}/db.sqlite3";
    };
  } // cfg.webSettings;

  webSettingsJSON = pkgs.writeText "${name}-settings.json" (builtins.toJSON webSettings);

  environment = {
    SETTINGS_JSON = builtins.concatStringsSep ":" (
      [ webSettingsJSON ] ++ 
      (if (cfg.webSettingsFile == null) then [] else [ cfg.webSettingsFile ])
      );
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
  options.services.${name} = with types; {

    enable = mkEnableOption name;

    listenAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = "Address the server will listen on.";
    };

    port = mkOption {
      type = port;
      default = 8000;
      description = "Port the server will listen on.";
    };

    dataDir = mkOption {
      type = str;
      default = "${name}";
      apply = (o: "/var/lib/" + o);
      description = "${name} state directory will be created by systemd in /var/lib.";
    };

    user = mkOption {
      default = name;
      type = str;
      description = "User account under which ${name} runs.";
    };

    group = mkOption {
      default = name;
      type = str;
      description = "Group account under which ${name} runs.";
    };

    webSettings = mkOption {
      type = attrs;
      default = { };
      description = "Overrides for the default ${name} Django settings. Do not store secure settings here!";
    };

    webSettingsFile = mkOption {
      type = nullOr path;
      default = { };
      description = "Overrides for the default ${name} Django settings. Takes precedence over `webSettings`";
    };

    environment = mkOption {
      type = attrs;
      default = { };
      description = "Defines environment variables.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ manageScript ];

    users.users.${cfg.user} = {
      description = "${name} service owner.";
      group = cfg.group;
      isSystemUser = true;
    };

    users.groups.${cfg.group} = { };

    systemd.services.${name} = {
      description = "${name} Service";
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        ${pkg}/manage.py migrate --noinput
      '';

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        EnvironmentFile = environmentFile;

        ExecStart = ''
          ${pkg}/manage.py runserver ${cfg.listenAddress}:${toString cfg.port}
        '';

        StateDirectory = removePrefix "/var/lib/" cfg.dataDir;
      };
    };
  };
}
