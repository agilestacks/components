#!/bin/sh -e

GIT_REMOTE="${GIT_REMOTE:-https://github.com/agilestacks/jenkins.git}"
BRANCH="${BRANCH:-master}"
SUBPATH="${SUBPATH:-init.groovy.d}"
GIT_LOCAL="${GIT_LOCAL:-/git}"
DEST_DIR="${DEST_DIR:-/opt/export}"

mkdir -p "$DEST_DIR"
mkdir -p "$GIT_LOCAL"
rm -rf "${GIT_LOCAL:?}"/*
rm -rf "${GIT_LOCAL}"/.git

echo "Getting git repositories"
cd "$GIT_LOCAL"
git init
git remote add -f origin "$GIT_REMOTE"
git fetch --depth=1 origin "$BRANCH"
git checkout "origin/$BRANCH" -- "$SUBPATH"

if [ -d "$GIT_LOCAL/$SUBPATH" ]; then
    cp -rpv "$GIT_LOCAL/$SUBPATH/." "$DEST_DIR"
else
    cp -pv "$GIT_LOCAL/$SUBPATH" "$DEST_DIR"
fi
