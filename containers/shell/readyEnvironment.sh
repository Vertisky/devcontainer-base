#!/bin/bash

# copy files from /mnt to /root to avoid messing with the host
cp -R /mnt/.docker /mnt/.ssh /mnt/.gitconfig /mnt/.bash_history /root

# add /workspace to safe github repos
git config --global --add safe.directory /workspace

# execute any files named setup*.sh in /root
# setopt no_nomatch
if ls /root/setup*.sh 1> /dev/null 2>&1; then
    for f in /root/setup*.sh; do
        [ -f "$f" ] && . "$f"
    done
fi

# setopt nomatch
