#!/bin/bash

tmp_dir="/tmp/bun_tmp"
app_name="bun"
version="0.6.2"
release="v0.6.2"

deb_url="https://github.com/oven-sh/bun/releases/download/bun-${release}/bun-linux-x64.zip"

# 创建临时目录, 用于下载官方包
if [ -d $tmp_dir ]; then
  rm -rf $tmp_dir
fi

if [ -d "./unpack" ]; then
  sudo rm -rf ./unpack
fi

if [ -f "./${app_name}_${version}.deb" ]; then
  rm "./${app_name}_${version}.deb"
fi

mkdir $tmp_dir

# 创建临时待打包目录
echo "创建待打包目录..."
mkdir -p "./unpack/DEBIAN"
mkdir -p "./unpack/usr/bin"

echo "下载官方原包..."
wget $deb_url -O "${tmp_dir}/bun-linux-x64.zip"


echo "下载完成, 解包中..."
unzip "${tmp_dir}/bun-linux-x64.zip" -d $tmp_dir

echo "解包完成, 复制到待打包目录..."
mv ${tmp_dir}/bun-linux-x64/* "./unpack/usr/bin/"

rm -rf $tmp_dir

echo "复制完成, 计算文件md5..."

cd ./unpack

find usr/ -type f | xargs md5sum > DEBIAN/md5sums

IFS=$'\t' read -ra size <<< "$(du -d 0)"

echo """
Package: bun
Version: ${version}
Section: devlop
Installed-Size: ${size[0]}
Architecture: amd64
Maintainer: Yutent <yutent.io@gmail.com>
Priority: optional
Homepage: https://bun.sh/
Description: Incredibly fast JavaScript runtime.
  Incredibly fast JavaScript runtime, bundler, transpiler and package manager – all in one.

""" > DEBIAN/control

echo '计算文件md5完成, 打包中...'

cd ..
sudo chown -R root:root unpack

dpkg-deb -b ./unpack "./${app_name}_${version}.deb"

echo "打包完成 :)"