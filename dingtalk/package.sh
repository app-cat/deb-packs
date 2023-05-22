#!/bin/bash

tmp_dir="/tmp/dingtalk_tmp"
app_name="dingtalk"
version="1.7.0.30419"
release="1.7.0-Release.30419"

deb_url="https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Release/com.alibabainc.dingtalk_${version}_amd64.deb"

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
mkdir -p "./unpack/usr/lib/dingtalk"
mkdir -p "./unpack/usr/share/applications"

source_dir="${tmp_dir}/dingtalk/opt/apps/com.alibabainc.dingtalk/files"
dtalk_dir="./unpack/usr/lib/dingtalk"
files_dir="${dtalk_dir}/files"

echo "下载官方原包..."
wget $deb_url -O "${tmp_dir}/dingtalk.deb"

echo "下载完成, 解包中..."
dpkg-deb -R "${tmp_dir}/dingtalk.deb" "${tmp_dir}/dingtalk"

echo "解包完成, 复制到待打包目录..."
mv "${source_dir}/${release}" $files_dir
mv "${source_dir}/logo.ico" "${dtalk_dir}/"
mv "${source_dir}/version" "${dtalk_dir}/"

rm -rf $tmp_dir

echo "复制完成, 创建可执行文件及程序桌面入口文件..."

echo """
[Desktop Entry]
Categories=Chat;
Comment=钉钉
Exec=dingtalk %u
GenericName=dingtalk
Icon=/usr/lib/dingtalk/logo.ico
Keywords=dingtalk;
MimeType=x-scheme-handler/dingtalk;
Name=钉钉
Type=Application
""" > ./unpack/usr/share/applications/dingtalk.desktop


echo """
#!/bin/bash

cd /usr/lib/dingtalk/files
./dingtalk_run $1
""" > ./unpack/usr/bin/dingtalk

chmod +x ./unpack/usr/bin/dingtalk

echo "创建完成, 修正包文件中..."

rm ${files_dir}/dingtalk_updater

mv ${files_dir}/com.alibabainc.dingtalk ${files_dir}/dingtalk_run

echo """
#!/bin/bash
echo "你在想屁吃~~"
exit 1
""" > ${files_dir}/dingtalk_updater

chmod +x ${files_dir}/dingtalk_updater

cp -rfv ${files_dir}/dingtalk_updater ${files_dir}/dingtalk_crash_report

rm -rfv ${files_dir}/libgtk-x11-2.0.so.*

rm -rfv ${files_dir}/libm.so.6 

rm -rfv ${files_dir}/Resources/i18n/tool/*.exe

rm -rfv ${files_dir}/Resources/qss/mac

rm -rfv ${files_dir}/Resources/web_content/NativeWebContent_*.zip

rm -rfv ${files_dir}/libstdc*

echo "修正完成, 计算文件md5..."

cd ./unpack

find usr/ -type f | xargs md5sum > DEBIAN/md5sums
IFS=$'\t' read -ra size <<< "$(du -d 0)"

echo """
Package: dingtalk
Version: ${version}
Architecture: amd64
Maintainer: Yutent <yutent.io@gmail.com>
Depends: libgtk2.0-0
Installed-Size: ${size[0]}
Section: chat
Priority: optional
Homepage: https://gov.dingtalk.com
Description: 钉钉
""" > DEBIAN/control

echo '计算文件md5完成, 打包中...'

cd ..
sudo chown -R root:root unpack

dpkg-deb -b ./unpack "./${app_name}_${version}.deb"

echo "打包完成 :)"