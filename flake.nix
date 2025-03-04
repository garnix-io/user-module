{
  description = ''
    A garnix module for adding Linux users and allowing remote access through `SSH`.

    [Documentation](https://garnix.io/docs/modules/user) - [Source](https://github.com/garnix-io/user-module).
  '';

  outputs =
    { self
    ,
    }:
    {
      garnixModules.default = { pkgs, lib, config, ... }:
    let
      userSubmodule.options = {
        user = lib.mkOption
          {
            type = lib.types.nonEmptyStr;
            description = "The Linux username.";
            example = "alice";
          } // { name = "user name"; };

        groups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "The groups the user belongs to.";
          example = [ "wheel" ];
          default = [ ];
        };

        shell = lib.mkOption {
          type = lib.types.enum [ "bash" "zsh" "fish" ];
          default = "bash";
          description = "The users login shell.";
        };

        authorizedSshKeys = lib.mkOption
          {
            type = lib.types.listOf lib.types.nonEmptyStr;
            description =
              ''The public SSH keys that can be used to log in as this user. (Note that you must
            use the IP address rather than domain for SSH.)'';
          } // { name = "SSH keys"; };
      };
    in
    {
        options = {
          user = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule userSubmodule);
            description = "An attrset of users.";
          };
        };

        config =
          {
            nixosConfigurations.default =
              builtins.attrValues (builtins.mapAttrs
                (name: projectConfig: {
                  users.users.${projectConfig.user} = {
                    extraGroups = projectConfig.groups;
                    isNormalUser = true;
                    shell = pkgs.${projectConfig.shell};
                    openssh.authorizedKeys.keys = projectConfig.authorizedSshKeys;
                  };
                  programs.zsh.enable = projectConfig.shell == "zsh";
                  programs.fish.enable = projectConfig.shell == "fish";
                  services.openssh = {
                    enable = true;
                    settings = {
                      PasswordAuthentication = false;
                      KbdInteractiveAuthentication = false;
                      AuthenticationMethods = "publickey";
                      PermitRootLogin = "prohibit-password";
                    };
                  };
                })
                config.user);
          };
      };
    };
}
