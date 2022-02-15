#!/bin/sh

set -e

[ -z "$ZIG_BIN" ] && ZIG_BIN=zig

OPTS="-Drelease-safe"

$ZIG_BIN build -Dfetch $OPTS

OUT_DIR=dist

#TODO add 'aarch64-windows-gnu' when zig has tier1 support for that 
TARGETS='x86_64-linux-musl aarch64-linux-musl x86_64-linux-gnu.2.23 aarch64-linux-gnu.2.23 x86_64-macos-gnu aarch64-macos-gnu x86_64-windows-gnu'

cross_compile_target(){
    TARGET=$1
    NAME=${TARGET%%.*}
    TARGET_DIR=zigup-$NAME
    echo "$OUT_DIR/$TARGET_DIR ... -Dtarget=$TARGET $OPTS"
    $ZIG_BIN build -p "$OUT_DIR/$TARGET_DIR" -Dtarget=$TARGET $OPTS
}

archive_target(){
    NAME=${1%%.*}
    TARGET_DIR=zigup-$NAME
    if [ "$TARGET_DIR" != *windows ]; then
        [ -e "$TARGET_DIR.tar.gz" ] && rm $TARGET_DIR.tar.gz
        tar -cvzf $TARGET_DIR.tar.gz $TARGET_DIR
    else
        [ -e "$TARGET_DIR.zip" ] && rm $TARGET_DIR.zip
        zip -r $TARGET_DIR.zip $TARGET_DIR
    fi
}

for T in $TARGETS; do
    cross_compile_target $T
done

cd $OUT_DIR

for T in $TARGETS; do
    archive_target $T
done

REL_VERSION=$1
[ -n "$REL_VERSION" ] || exit 0

REL_TOKEN=$2
[ -n "$REL_TOKEN" ] || REL_TOKEN=`cat gh-release-token`

REL_USER=dyu

upload_target(){
    NAME=${1%%.*}
    TARGET_DIR=zigup-$NAME
    FILE_SUFFIX='.zip'
    [ "$TARGET_DIR" != *windows* ] && FILE_SUFFIX='.tar.gz'
    GITHUB_TOKEN=$REL_TOKEN github-release upload \
        --user $REL_USER \
        --repo zigup \
        --tag v$REL_VERSION \
        --name $TARGET_DIR \
        --file $TARGET_DIR.$FILE_SUFFIX
}

GITHUB_TOKEN=$REL_TOKEN github-release release \
    --user $REL_USER \
    --repo zigup \
    --tag v$REL_VERSION \
    --name "zigup-v$REL_VERSION" \
    --description "zigup binaries for linux/mac/windows"

for T in $TARGETS; do
    upload_target $T
done
