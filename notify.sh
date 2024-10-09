#!/usr/bin/env bash


LOCAL_VER=$(nixos-version | cut -c1-5)

if [ "--test" == "$1" ]
  then
    LOCAL_VER=0.0
fi

#get latest stable version from git
LATEST_VER=$(git ls-remote --heads https://github.com/NixOS/nixpkgs  'nixos-*' | sed -nr 's:^([^ ]+) *refs/heads/(nixos-[0-9.]+)$:\2 \1:p' | sort -V | tail -n1 | grep -o -P '([0-9]*\.[0-9]+)')

#alternative way to get the current version by using the manual 
#LATEST_VER=$(curl -L -s https://nixos.org/manual/nixos/stable/ | grep -m1 "Version" | grep -o -P '(?<=Version\s).*(?=</h2)')

if [ "$LOCAL_VER" == "$LATEST_VER" ]; then
    echo "already on latest stable $LATEST_VER"
else
   echo "Update Needed $LOCAL_VER != $LATEST_VER"
   notify-send -a "New update available" -u critical "system is outdated !" "Please update NixOS to $LATEST_VER\n$LOCAL_VER is currently used"
fi
