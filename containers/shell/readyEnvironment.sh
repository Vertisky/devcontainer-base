#!/bin/sh

# copy files from /mnt to /root to avoid messing with the host
cp -R /mnt/.docker /mnt/.ssh /mnt/.gitconfig /mnt/.zsh_history /root

# add /workspace to safe github repos
git config --global --add safe.directory /workspace

# execute any files named setup*.sh in /root
for f in /root/setup*.sh; do
    [ -f "$f" ] && . "$f"
done
