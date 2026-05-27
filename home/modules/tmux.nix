# Tmux + Zellij — turn on via settings.features.tmux.
# Tmux config covers true-color, OSC-52 clipboard for SSH, vi-style copy mode,
# pane navigation (vim-style hjkl), and an Alt-c secondary prefix.
# Zellij ships with a dracula theme written to ~/.config/zellij/themes/.
{ config, lib, pkgs, settings, ... }:

with lib;

{
  config = mkIf (settings.features.tmux or false) {
    programs.tmux = {
      enable        = true;
      terminal      = "tmux-256color";
      baseIndex     = 1;
      escapeTime    = 0;
      historyLimit  = 50000;
      keyMode       = "vi";
      clock24       = true;
      mouse         = true;
      focusEvents   = true;

      extraConfig = ''
        # Alt-c secondary prefix
        set -g prefix2 M-c

        # True-color (24bit)
        set -as terminal-features ",xterm-256color:RGB"
        set -as terminal-features ",tmux-256color:RGB"
        set -as terminal-overrides ",*:Tc"

        # Pass COLORTERM into the inner shell
        set -ga update-environment "COLORTERM"
        set-environment -g COLORTERM "truecolor"

        # OSC-52 clipboard (works over SSH)
        set -g set-clipboard on
        set -g allow-passthrough on

        # Vi copy mode with OSC-52
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'cat | base64 -w0 | xargs -I{} printf "\033]52;c;{}\007"'
        bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel 'cat | base64 -w0 | xargs -I{} printf "\033]52;c;{}\007"'

        # Status bar
        set -g status-bg colour235
        set -g status-fg white
        set -g status-left '#[fg=green]#S #[fg=yellow]#H '
        set -g status-right '#[fg=cyan]%Y-%m-%d %H:%M'

        # Splits (preserve cwd)
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # Vim-style pane navigation
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Alt+arrows to resize
        bind -n M-Left  resize-pane -L 5
        bind -n M-Right resize-pane -R 5
        bind -n M-Up    resize-pane -U 5
        bind -n M-Down  resize-pane -D 5

        # Reload config
        bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

        # Session logging
        bind P pipe-pane -o "cat >>~/tmux-#W.log" \; display "Logging to ~/tmux-#W.log"

        # Auto renumber windows after kill
        set -g renumber-windows on
      '';
    };

    programs.zellij = {
      enable = true;
      settings = {
        theme             = "dracula";
        default_shell     = "bash";
        pane_frames       = true;
        simplified_ui     = false;
        copy_on_select    = true;
        scrollback_editor = "vim";
        mouse_mode        = true;
      };
    };

    xdg.configFile."zellij/themes/dracula.kdl".text = ''
      themes {
        dracula {
          fg "#F8F8F2"
          bg "#282A36"
          black "#21222C"
          red "#FF5555"
          green "#50FA7B"
          yellow "#F1FA8C"
          blue "#BD93F9"
          magenta "#FF79C6"
          cyan "#8BE9FD"
          white "#F8F8F2"
          orange "#FFB86C"
        }
      }
    '';
  };
}
