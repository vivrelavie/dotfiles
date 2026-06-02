fish_add_path --global ~/.local/bin

# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        set -x STARSHIP_CONFIG ~/.cache/matugen/starship.toml
        starship init fish | source
        enable_transience
    end
    
    # Colors
    # if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    #     cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    # end

    if test -f ~/.cache/matugen/fastfetch.jsonc
        fastfetch --config ~/.cache/matugen/fastfetch.jsonc
    else
        fastfetch
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    alias sp spotify_player
    alias reloadwp ~/.config/hypr/scripts/reload.sh
    alias emu8086 "wine ~/.wine/drive_c/emu8086/emu8086.exe"
    alias agentswitcher ~/Documents/Projects/AgentSwitcher/agentswitcher
    alias charles "codex"

    if type -q eza
        if test "$TERM" != "linux"
            alias ls 'eza --icons'
        else
            alias ls eza
        end
        if not functions -q __codex_original_cd
            functions -c cd __codex_original_cd
        end

        function cd --wraps=__codex_original_cd --description 'Change directory and list contents with eza'
            __codex_original_cd $argv; or return

            if test "$TERM" != "linux"
                eza --icons
            else
                eza
            end
        end
    end

    # Old blackhole neofetch animation launcher.
    # Commented out so the shell can be switched to a txt-based ASCII source instead.
    # if not set -q CODEX_THREAD_ID; and not set -q CODEX_CI
    #     neofetch-anim
    # end
end
