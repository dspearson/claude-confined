# justfile for claude-confined
# Run 'just' to see available commands

# Show available commands (default)
[private]
default:
    @echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    @echo "⠀⠀⠀⠀⠀⠀⠀⢀⣤⠶⠶⠟⠛⠛⠛⠛⠻⠿⠷⣶⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀"
    @echo "⠀⠀⠀⠀⠀⣠⠞⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⢿⣷⣄⠀⠀⠀⠀⠀"
    @echo "⠀⠀⠀⢠⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣷⡀⠀⠀⠀"
    @echo "⠀⠀⢠⡟⠀⠀⠀⠀⠀⢀⣠⣤⣴⠶⠶⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣄⠀⠀"
    @echo "⠀⢀⣿⠁⠀⠀⠀⢀⣴⠟⠛⢿⣟⠛⢶⡀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⡄"
    @echo "⠀⢸⡏⠀⠀⠀⠀⣾⡇⠀⠀⠀⣿⠃⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠛⠇⠀     Claude"
    @echo "⠀⢸⡇⠀⠀⠀⠀⢹⣇⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⡀⠀⠀⠀⠀⢰⣶⣦⠀    Confined"
    @echo "⠀⠸⣧⠀⠀⠀⠀⠀⠻⣦⣀⠀⠀⠀⣀⣤⡾⠛⠉⠉⠉⠛⣷⡄⠀⠀⢈⡉⠋"
    @echo "⠀⠀⢻⡆⠀⠀⠀⠀⠀⠈⠙⠛⠛⠛⠉⠁⠀⠀⠀⠀⠀⠀⢸⣷⠀⠀⣿⡿⠀"
    @echo "⠀⠀⠈⢻⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⠇⠀⣸⣿⠃⠀"
    @echo "⠀⠀⠀⠀⠻⣧⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠋⠀⣴⣿⠃⠀⠀⠀"
    @echo "⠀⠀⠀⠀⠀⠈⠛⢷⣤⣀⠀⠀⠀⠀⠀⠀⠀⢀⣠⡾⠋⠀⣠⣾⣿⠏⠀⠀⠀⠀"
    @echo "⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⠓⠶⠶⠶⠖⠛⠋⠁⠀⠀⣴⣿⣿⠃⠀⠀⠀⠀⠀"
    @echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠁⠀⠀⠀⠀⠀⠀"
    @echo ""
    @just --list
    @echo ""

# Install claude-confined (supports: --allow PATH, repeatable)
install *args:
    perl {{justfile_directory()}}/bin/install {{args}}

# Uninstall claude-confined
uninstall:
    perl {{justfile_directory()}}/bin/install --uninstall

# Run security tests in sandbox (copies test to ~/.claude/tmp first)
test:
    @mkdir -p ~/.claude/tmp
    @cp {{justfile_directory()}}/bin/run-tests ~/.claude/tmp/run-tests
    @chmod +x ~/.claude/tmp/run-tests
    cd {{justfile_directory()}} && claude-confined --allow {{justfile_directory()}} --bash "perl ~/.claude/tmp/run-tests"
    @rm -f ~/.claude/tmp/run-tests

# List available optional AppArmor profiles
list-profiles:
    perl {{justfile_directory()}}/bin/manage-profiles list

# Show status of optional AppArmor profiles
profile-status:
    perl {{justfile_directory()}}/bin/manage-profiles status

# Enable an optional AppArmor profile (e.g., 'just enable-profile emacs-config')
enable-profile PROFILE:
    perl {{justfile_directory()}}/bin/manage-profiles enable {{PROFILE}}

# Disable an optional AppArmor profile (e.g., 'just disable-profile emacs-config')
disable-profile PROFILE:
    perl {{justfile_directory()}}/bin/manage-profiles disable {{PROFILE}}

# Test optional profiles for syntax errors
test-profiles:
    perl {{justfile_directory()}}/bin/test-optional-profiles
