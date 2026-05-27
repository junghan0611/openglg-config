# Extra shell — turn on via settings.features.shell.
# Adds aliases, prompt, FZF integration, atuin history, zoxide cd, and an
# emacsclient wrapper (e/v/ec/ecn) that auto-detects 24-bit true-color terms.
{ config, lib, pkgs, settings, ... }:

with lib;

{
  config = mkIf (settings.features.shell or false) {
    programs.bash = {
      enableCompletion = true;
      historyControl   = [ "erasedups" "ignoredups" "ignorespace" ];
      historyFileSize  = 10000;
      historySize      = 10000;

      shellAliases = {
        # Git
        gco   = "git checkout";
        gch   = "git checkout HEAD";
        gdiff = "git diff";
        gs    = "git status";
        gsta  = "git status";
        gadd  = "git add -v";
        gcom  = "git commit";
        gcomm = "git commit -m";
        gl    = "git prettylog";
        glog  = "git log --oneline --graph -10";
        gbl   = "git branch --list";
        gpm   = "git push -u origin main";
        gpull = "git pull";

        # ls (eza)
        ls = "eza";
        ll = "eza -la";
        la = "eza -a";
        lt = "eza --tree --level=2";
        l  = "eza -CF";

        # Modern CLI
        cat  = "bat --paging=never";
        grep = "rg";
        find = "fd";

        # Navigation
        ".."  = "cd ..";
        "..." = "cd ../..";
      };

      bashrcExtra = ''
        # Load ~/.profile so non-interactive SSH gets the same PATH
        [[ -f ~/.profile ]] && . ~/.profile
      '';

      initExtra = ''
        # Ctrl+D safety
        export IGNOREEOF=10

        # GPG TTY
        export GPG_TTY=$(tty)

        # Prompt
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

        # dircolors
        eval "$(dircolors -b)"

        # PNPM
        export PNPM_HOME="$HOME/.local/share/pnpm"
        case ":$PATH:" in
          *":$PNPM_HOME:"*) ;;
          *) export PATH="$PNPM_HOME:$PATH" ;;
        esac

        export PATH="$HOME/.local/bin:$PATH"

        # FZF key bindings
        if command -v fzf &> /dev/null; then
          source ${pkgs.fzf}/share/fzf/key-bindings.bash
          source ${pkgs.fzf}/share/fzf/completion.bash
        fi

        # emacsclient wrapper — 24bit true-color auto-detect
        e() {
            local term="$TERM"
            if { [ "$COLORTERM" = truecolor ] || [ "$COLORTERM" = 24bit ]; } \
                && [ "$(tput colors 2>/dev/null)" -lt 257 ]; then
                local stub="''${TERM%%-*}"
                if infocmp "''${stub}-direct" >/dev/null 2>&1; then
                    term="''${stub}-direct"
                else
                    term="xterm-direct"
                fi
            fi
            TERM="$term" emacsclient -s user -nw "$@"
        }
        alias v='e'
        alias ec='emacsclient -s user -n'
        alias ecn='emacsclient -s user -c -n'

        # Host-local extras (gitignored)
        if [ -f "$HOME/.bashrc.local" ]; then
           source "$HOME/.bashrc.local"
        fi
      '';
    };

    home.sessionVariables = {
      TERM      = "xterm-256color";
      PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
      EDITOR    = "emacsclient -s user";
    };

    home.sessionPath = [
      "${config.home.homeDirectory}/.local/share/pnpm"
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/go/bin"
      "${config.home.homeDirectory}/bin"
    ];

    home.file.".fdignore".text = ''
      .git
      node_modules
      .DS_Store
    '';

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.fzf = {
      enable = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--border"
        "--reverse"
        "--color=dark"
      ];
    };

    programs.atuin = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        sync_frequency = "1h";
        search_mode    = "fuzzy";
        filter_mode    = "directory";
        flags          = [ "--disable-ctrl-r" ];
      };
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
