#!/bin/bash

tmp_dir="/tmp/neovim_tmp"
app_name="neovim"
version="0.9.0-1"
release="v0.9.0"

deb_url="https://github.com/neovim/neovim/releases/download/${release}/nvim-linux64.tar.gz"

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
mkdir -p "./unpack/usr"

echo "下载官方原包..."
wget $deb_url -O "${tmp_dir}/nvim-linux64.tar.gz"


echo "下载完成, 解包中..."
tar -xzvf "${tmp_dir}/nvim-linux64.tar.gz" -C $tmp_dir

ls -lsh $tmp_dir

echo "解包完成, 复制到待打包目录..."
mv ${tmp_dir}/nvim-linux64/* "./unpack/usr/"

rm -rf $tmp_dir

echo "复制完成, 计算文件md5..."

cd ./unpack

find usr/ -type f | xargs md5sum > DEBIAN/md5sums
IFS=$'\t' read -ra size <<< "$(du -d 0)"

echo """
Package: neovim
Version: ${version}
Architecture: amd64
Depends: libc6 (>= 2.29), libgcc-s1 (>= 3.3)
Breaks: neovim-runtime (<= 0.7.2-7)
Replaces: neovim-runtime (<= 0.7.2-7)
Maintainer: Yutent <yutent.io@gmail.com>
Priority: optional
Section: devel
Installed-Size: ${size[0]}
Description: heavily refactored vim fork
 Neovim is a fork of Vim focused on modern code and features, rather than
 running in legacy environments.
 .
 msgpack API enables structured communication to/from any programming language.
 Remote plugins run as co-processes that communicate with Neovim safely and
 asynchronously.
 .
 GUIs (or TUIs) can easily embed Neovim or communicate via TCP sockets using
 the discoverable msgpack API.

""" > DEBIAN/control

echo '计算文件md5完成, 打包中...'

cd ..
sudo chown -R root:root unpack

dpkg-deb -b ./unpack "./${app_name}_${version}.deb"

echo "打包完成 :)"