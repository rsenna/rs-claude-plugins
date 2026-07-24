#!/usr/bin/env fish

set --function fish_trace on # FOR DEBUGGING

# delete all files but this script
fd . --exclude update.fish | xargs rm -rf {}

## CUSTOM: Imported from ClawHub: https://clawhub.ai/...
## format: https://clawhub.ai/USER/skills/SKILL

set -l CLAWHUB_OWNER_HANDLE USER
set -l CLAWHUB_SKILL_NAME   SKILL
set -l FILES LIST OF FILES OR FOLDERS

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
