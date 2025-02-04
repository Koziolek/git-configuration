#!/usr/bin/env bash

##
# Usage/help function for the entire script
##
function bash_customs_usage() {
    cat <<EOF
Usage: source this script or call its functions directly in your shell.

Available functions:

  1) source_if_exists FILE
       - Sources FILE.sh from \$BASH_CONFIGURATION_DIR if it exists.

  2) parse_git_branch
       - Prints the current git branch (if in a git repo).

  3) make_me_sudo
       - Sets up environment variables to use sudo without a password prompt
         (if not already root).

  4) unmake_me_sudo
       - Revokes sudo privileges set by make_me_sudo.

  5) order66 PATTERN
       - Kills processes matching PATTERN.

  6) exterminatus PATTERN
       - Kills processes matching PATTERN (same as order66, different name).

  7) heif_to_png
       - Converts all *.heic files in the current directory to PNGs using heif-convert.

  8) resize_to_full
       - If running in X11, attempts to full-screen the currently active window.

  9) run_tmux
       - Attaches to tmux or starts a new session if tmux is installed
         and not already in a tmux session.

  10) print_logo
       - Displays an ASCII art logo using neofetch from \$BASH_CONFIGURATION_DIR.

  11) who_use_port
       - List processes that use given port.

Additional notes:
  - Ensure \$BASH_CONFIGURATION_DIR is set to the directory containing your
    configuration files and the "logo-ascii-art.txt" for print_logo.
  - Some functions require extra tools to be installed (e.g., neofetch,
    heif-convert, xdotool, tmux).

EOF
}

##
# Sources a file from $BASH_CONFIGURATION_DIR if it exists
# Usage: source_if_exists filename
##
function source_if_exists() {
    if [ $# -lt 1 ]; then
        echo "Usage: source_if_exists FILE"
        return 1
    fi

    local filename="$1"
    if [ -z "$BASH_CONFIGURATION_DIR" ]; then
        echo "Warning: \$BASH_CONFIGURATION_DIR is not set. Cannot source files reliably."
    fi

    local filepath="${BASH_CONFIGURATION_DIR}/${filename}.sh"
    if [ -f "$filepath" ]; then
        # shellcheck source=/dev/null
        . "$filepath"
    else
        echo "File '${filename}.sh' does not exist in '${BASH_CONFIGURATION_DIR}'"
    fi
}

##
# Prints the current git branch (if in a git repo)
##
function parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

##
# Sets up environment variables to use sudo if not already root
##
function make_me_sudo () {
    export SUDO=''
    export RESET_SUDO=0
    if (( EUID != 0 )); then
       SUDO='sudo'
       RESET_SUDO=1
    fi
    return 0
}

##
# Revokes sudo privileges set by make_me_sudo
##
function unmake_me_sudo () {
    if (( RESET_SUDO != 0 )); then
        $SUDO -K
    fi
    unset SUDO
    unset RESET_SUDO
}

##
# Kills processes matching a given pattern
# Usage: order66 PATTERN
##
function order66 () {
    if [ $# -lt 1 ]; then
        echo "Usage: order66 PATTERN"
        return 1
    fi
    exterminatus "$@"
}

##
# Kills processes matching a given pattern
# Usage: exterminatus PATTERN
# (Same as order66)
##
function exterminatus () {
    if [ $# -lt 1 ]; then
        echo "Usage: exterminatus PATTERN"
        return 1
    fi
    local pattern="$1"
    # Use pgrep to avoid killing the grep process itself
    pgrep -f "$pattern" | xargs -r kill -9
}

##
# Converts all *.heic files in the current directory to PNGs
# Requires heif-convert
##
function heif_to_png () {
    if ! command -v heif-convert >/dev/null 2>&1; then
        echo "Error: 'heif-convert' is not installed or not found in PATH."
        return 1
    fi

    local count=0
    for i in *.heic; do
        # If no *.heic files exist, stop
        [ -e "$i" ] || { echo "No .heic files found."; return 0; }

        heif-convert "$i" "$(basename -s .heic "$i").png"
        ((count++))
    done
    echo "Converted $count file(s) from .heic to .png."
}

##
# Resizes the currently active window to full screen if running under X11
# and using xdotool
##
function resize_to_full () {
    # Only run if X11 session
    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        # Check if xdotool is installed
        if ! command -v xdotool >/dev/null 2>&1; then
            return 0
        fi

        local win_id
        win_id="$(xdotool getactivewindow)"
        local current_size
        current_size="$(xwininfo -id "$win_id" -stats \
            | egrep '(Width|Height):' \
            | awk '{print $NF}' \
            | xargs echo \
            | sed -e 's/ /x/')"

        local max_size
        max_size="$(xrandr | egrep '\*' | awk '{print $1}' | head -n 1)"

        if [ "$current_size" != "$max_size" ]; then
            xdotool key F11
        fi
    fi
}

##
# Runs tmux if not inside a tmux session already
##
function run_tmux () {
    if command -v tmux >/dev/null 2>&1; then
        # If not in a tmux session and not in a TERM that starts with "screen"
        if [[ ! "$TERM" =~ screen ]] && [ -z "$TMUX" ]; then
            exec tmux
        fi
    fi
}

##
# Prints an ASCII art logo using neofetch
# Expects $BASH_CONFIGURATION_DIR/logo-ascii-art.txt to exist
##
function print_logo () {
    if ! command -v neofetch >/dev/null 2>&1; then
        echo "Error: 'neofetch' is not installed or not found in PATH."
        return 1
    fi

    if [ -z "$BASH_CONFIGURATION_DIR" ] || [ ! -f "$BASH_CONFIGURATION_DIR/logo-ascii-art.txt" ]; then
        echo "Error: logo-ascii-art.txt not found in \$BASH_CONFIGURATION_DIR."
        return 1
    fi

    neofetch --ascii "$BASH_CONFIGURATION_DIR/logo-ascii-art.txt"
}

##
# List processes that use given PORT if --sudo is set then run it as sudo.
##
function who_use_port () {
    if [ $# -lt 1 ]; then
        echo "Usage: who_use_port [--sudo] PORT"
        return 1
    fi

    local root_mode=false
    local port

    # Check if the first argument is --sudo
    if [ "$1" == "--sudo" ]; then
        root_mode=true
        shift # Remove the --sudo argument
    fi

    port="$1"

    if [ -z "$port" ]; then
        echo "Usage: who_use_port [--sudo] PORT"
        return 1
    fi

    if $root_mode; then
        make_me_sudo
    fi

    # Use pgrep to avoid killing the grep process itself
    $SUDO netstat -tulpn | grep "$port" | awk '!seen[$0]++'

    if $root_mode; then
        unmake_me_sudo
    fi
}


##
# Export functions so they remain available after 'source'
##
export -f bash_customs_usage
export -f source_if_exists
export -f parse_git_branch
export -f make_me_sudo
export -f unmake_me_sudo
export -f order66
export -f exterminatus
export -f heif_to_png
export -f resize_to_full
export -f run_tmux
export -f print_logo
export -f who_use_port
