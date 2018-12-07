#!/bin/bash -ex
SRC_DIR=${SRC_DIR:-/usr/share/jenkins/ref/init.groovy.d}
DEST_DIR="${DEST_DIR:-/tmp/export/init.groovy.d}"

mkdir -p "$DEST_DIR"
cp -rpnv "$SRC_DIR/." "$DEST_DIR"
