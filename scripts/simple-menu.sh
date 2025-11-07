#!/bin/bash

# Simple, reliable menu selection using bash select
# Much cleaner than trying to handle arrow keys manually

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Function to display a menu and get selection
show_menu() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice

    echo -e "\n${CYAN}${prompt}${NC}\n" >&2

    PS3=$'\n'"Please select (1-${#options[@]}): "

    select opt in "${options[@]}"; do
        if [ -n "$opt" ]; then
            MENU_SELECTION="$opt"
            echo -e "${GREEN}✓${NC} Selected: $opt\n" >&2
            return 0
        else
            echo -e "${YELLOW}Invalid selection, please try again${NC}" >&2
        fi
    done < /dev/tty
}

# Export for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f show_menu
fi