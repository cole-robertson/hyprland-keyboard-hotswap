#!/bin/bash

# Beautiful arrow-key menu selection for bash
# Returns the selected option

# Usage: select_option "prompt" "option1" "option2" "option3" ...

select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=0
    local key=""

    # Colors and formatting
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local REVERSE='\033[7m'
    local NC='\033[0m'

    # Hide cursor
    tput civis

    # Trap to show cursor on exit
    trap 'tput cnorm' EXIT INT TERM

    # Display prompt
    echo -e "${CYAN}${prompt}${NC}\n" >&2

    while true; do
        # Clear lines for menu redraw (move cursor up and clear)
        if [ "$key" != "" ]; then
            for ((i=0; i<${#options[@]}; i++)); do
                tput cuu1  # Move cursor up
                tput el    # Clear line
            done
        fi

        # Display options
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                # Highlighted option
                echo -e "  ${REVERSE}▶ ${options[$i]}${NC}" >&2
            else
                echo -e "    ${options[$i]}" >&2
            fi
        done

        # Read single keypress
        IFS= read -rsn1 key < /dev/tty

        # Handle arrow keys (they send escape sequences)
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key < /dev/tty  # Read the rest of arrow key sequence
            case "$key" in
                '[A') # Up arrow
                    ((selected--))
                    if [ $selected -lt 0 ]; then
                        selected=$((${#options[@]} - 1))
                    fi
                    ;;
                '[B') # Down arrow
                    ((selected++))
                    if [ $selected -ge ${#options[@]} ]; then
                        selected=0
                    fi
                    ;;
            esac
        elif [[ $key == "" ]]; then  # Enter key
            break
        elif [[ $key == "q" || $key == "Q" ]]; then  # Q to quit
            tput cnorm  # Show cursor
            return 1
        fi

        # Handle number keys for quick selection
        if [[ $key =~ ^[1-4]$ ]]; then
            local num=$((key - 1))
            if [ $num -lt ${#options[@]} ]; then
                selected=$num
                break
            fi
        fi
    done

    # Show cursor again
    tput cnorm

    # Export the selected option as a global variable
    SELECTED_OPTION="${options[$selected]}"

    # Also echo it for backward compatibility
    echo "${options[$selected]}"
    return 0
}

# Export function if sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f select_option
fi