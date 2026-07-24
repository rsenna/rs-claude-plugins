#!/usr/bin/env fish

# set --function fish_trace on # FOR DEBUGGING

# delete all files but this script
fd . --exclude update.fish | xargs rm -rf {}

## CUSTOM: Imported from ClawHub: https://clawhub.ai/psprosen-dev/skills/obsidian
## format: https://clawhub.ai/USER/skills/SKILL

set -l CLAWHUB_OWNER_HANDLE psprosen-dev
set -l CLAWHUB_SKILL_NAME   obsidian
set -l FILES SKILL.md skill-card.md references/ references/FUNCTIONS_REFERENCE.md

## END

## COMMON (mostly)

set -l URL_FMT https://clawhub.ai/api/v1/skills/$CLAWHUB_SKILL_NAME/file?path={}&ownerHandle=$CLAWHUB_OWNER_HANDLE

for file in $FILES
    if [ (path extension $file) = '.md' ]
        set -l url_path (string replace '/' '%2F' $file)
        set -l url (string replace '{}' $url_path $URL_FMT )
        curl -L $url -o $file
    else
        mkdir -p $file
    end
end

## END
