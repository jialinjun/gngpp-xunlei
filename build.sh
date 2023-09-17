#!/bin/bash

set -e

[ ! -d uploads ] && mkdir uploads
[ ! -d bin ] && mkdir bin

root=$(pwd)
target_list=(x86_64-unknown-linux-musl aarch64-unknown-linux-musl)
for target in ${target_list[@]}; do

  if [[ $target == *"aarch64"* ]]; then
    arch=aarch64 bash +x unpack.sh
  else
    bash +x unpack.sh
  fi

  # default feature
  cargo zigbuild --release --target=$target
  upx --lzma target/$target/release/xunlei
  cargo deb --target=$target --no-build --no-strip
  cd target/$target/release
  tar czvf xunlei-$tag-$target.tar.gz xunlei
  shasum -a 256 xunlei-$tag-$target.tar.gz >xunlei-$tag-$target.tar.gz.sha256
  mv xunlei-$tag-$target.tar.gz $root/uploads/
  mv xunlei-$tag-$target.tar.gz.sha256 $root/uploads/
  cd -
  cd target/$target/debian
  rename 's/.*/xunlei-'$tag'-'$target'.deb/' *.deb
  mv ./* $root/uploads/
  cd -

  # launcher feature
  mkdir -p xunlei-launcher-$tag-$target/bin
  mv bin/* xunlei-launcher-$tag-$target/bin/
  cargo zigbuild --release --target=$target --no-default-features --features launcher
  upx --lzma target/$target/release/xunlei
  mv target/$target/release/xunlei xunlei-launcher-$tag-$target/
  tar -czvf xunlei-launcher-$tag-$target.tar.gz xunlei-launcher-$tag-$target/*
  shasum -a 256 xunlei-launcher-$tag-$target.tar.gz >xunlei-launcher-$tag-$target.tar.gz.sha256
  mv xunlei-launcher-$tag-$target.tar.gz uploads/
  mv xunlei-launcher-$tag-$target.tar.gz.sha256 uploads/
  
  rm -rf xunlei-launcher-$tag-$target
  ls -lah uploads
done
