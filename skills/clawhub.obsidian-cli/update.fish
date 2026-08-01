#!/usr/bin/env fish

# set --function fish_trace on # FOR DEBUGGING

# delete all files but this script
fd . --exclude update.fish | xargs rm -rf {}

## Source moved to GitHub: https://github.com/slmoloch/obsidian-official-cli-skill
## ClawHub source (dead): https://clawhub.ai/slmoloch/skills/obsidian-oficial-cli

set -l GITHUB_RAW https://raw.githubusercontent.com/slmoloch/obsidian-official-cli-skill/main
set -l FILES SKILL.md

for file in $FILES
    curl -fsSL "$GITHUB_RAW/$file" -o $file
end

