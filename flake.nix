{
  description = "A garnix module for Linux users.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs =
    { self
    , nixpkgs
    ,
    }:
    let
      lib = nixpkgs.lib;

      userSubmodule.options = {
        user = lib.mkOption {
          type = lib.types.nonEmptyStr;
          description = "The linux username.";
          example = "alice";
        };

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

        authorizedSshKeys = lib.mkOption {
          type = lib.types.listOf lib.types.nonEmptyStr;
          description =
            ''The public SSH keys that can be used to log in as this user. (Note that you must
            use the IP address rather than domain for SSH.)'';
        };
      };
    in
    {
      garnixModules.default = { pkgs, config, ... }: {
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
                })
                config.user);
          };
      };
    };
}

