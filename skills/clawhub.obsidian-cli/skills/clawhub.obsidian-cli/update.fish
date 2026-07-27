#!/usr/bin/env fish

# set --function fish_trace on # FOR DEBUGGING

# delete all files but this script
fd . --exclude update.fish | xargs rm -rf {}

## CUSTOM: Imported from GitHub: https://github.com/slmoloch/obsidian-official-cli-skill
## Not available via the ClawHub API (returns "Skill not found" as of 2026-07-27).

set -l GITHUB_OWNER slmoloch
set -l GITHUB_REPO  obsidian-official-cli-skill
set -l GITHUB_BRANCH main
set -l FILES SKILL.md

## END

## COMMON (mostly)

set -l URL_FMT https://raw.githubusercontent.com/$GITHUB_OWNER/$GITHUB_REPO/$GITHUB_BRANCH/{}

for file in $FILES
    set -l url (string replace '{}' $file $URL_FMT)
    curl -L $url -o $file
end

## END
