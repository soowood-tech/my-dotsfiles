# angelOS: the terminal in hell (Settings → Y2K → Terminal in hell).
# Written by angelOS (scripts/terminal-hell.py) — edits here are overwritten.
status is-interactive; or return
set -l __angelos_dir (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/angelos/terminal
test -f $__angelos_dir/realm; or return
test (string trim < $__angelos_dir/realm) = hell; or return
# the circle's colours for the command line — this session only, the universal colours stay yours
set -g fish_color_command e2703f
set -g fish_color_keyword c99a5e
set -g fish_color_param d9cbbd
set -g fish_color_quote b08f52
set -g fish_color_redirection a8473a
set -g fish_color_end 9c8f85
set -g fish_color_operator c99a5e
set -g fish_color_escape 8a4a6a
set -g fish_color_error c4604c --bold
set -g fish_color_autosuggestion 9c8f85
set -g fish_color_comment 9c8f85
set -g fish_color_selection --background=1f1716
set -g fish_color_search_match --background=16100f
# fastfetch in the circle (the greeting runs it: CachyOS's fish config does)
if test -f $__angelos_dir/fastfetch.jsonc
    function fastfetch --wraps fastfetch
        command fastfetch --config (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/angelos/terminal/fastfetch.jsonc $argv
    end
end
# one of her lines before the first prompt (after fastfetch)
function __angelos_hell_line --on-event fish_prompt
    functions -e __angelos_hell_line
    set -l file (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/angelos/terminal/hell-lines.txt
    test -s $file; or return
    set -l lines (string match -v -r '^\s*$' < $file)
    test (count $lines) -gt 0; or return
    set_color e2703f; printf '⛧ '
    set_color d9cbbd; printf '%s' $lines[(random 1 (count $lines))]
    set_color normal; echo
end
