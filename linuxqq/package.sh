#!/bin/bash

tmp_dir="/tmp/linuxqq_tmp"
app_name="linuxqq"
version="3.1.2.12912"
release="3.1.2-12912"
_hash="80d33f88"

deb_url="https://dldir1.qq.com/qqfile/qq/QQNT/${_hash}/linuxqq_${release}_amd64.deb"

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
wget $deb_url -O "${tmp_dir}/linuxqq.deb"


echo "下载完成, 解包中..."
dpkg-deb -R "${tmp_dir}/linuxqq.deb" "${tmp_dir}/linuxqq"

echo "解包完成, 复制到待打包目录..."
cp -r "${tmp_dir}/linuxqq/opt" "./unpack/"
cp -r "${tmp_dir}/linuxqq/usr" "./unpack/"

rm -rf $tmp_dir

echo "复制完成, 创建可执行文件及程序桌面入口文件..."

echo """
[Desktop Entry]
Name=QQ
Exec=linuxqq %U
Terminal=false
Type=Application
Icon=/usr/share/icons/hicolor/512x512/apps/qq.png
StartupWMClass=QQ
Categories=Network;
Comment=QQ
""" > "./unpack/usr/share/applications/qq.desktop"

echo """
[Desktop Entry]
Type=Application
NoDisplay=true
Name=QQ Channel JSBridge URL Handler
Exec=/usr/bin/printf \"%u\"
StartupNotify=false
MimeType=x-scheme-handler/jsbridge;
""" > "./unpack/usr/share/applications/qq_channel_jsbridge_handler.desktop"

echo """
#!/bin/bash

USER_RUN_DIR=\"/run/user/\$(id -u)\"
DOWNLOAD_DIR=\"\$(xdg-user-dir DOWNLOAD)/QQ Files\"
CONFIG_HOME=\"\${HOME}/.config\"
QQ_APP_DIR=\"\${HOME}/.config/QQ\"

if [ ! -d \"\$QQ_APP_DIR\" ]; then
  mkdir \"\$QQ_APP_DIR\"
fi

if [ ! -d \"\$DOWNLOAD_DIR\" ]; then
  mkdir \"\$DOWNLOAD_DIR\"
fi


bwrap --new-session --die-with-parent --cap-drop ALL --unshare-user-try --unshare-pid --unshare-cgroup-try \\
  --symlink usr/lib /lib \\
  --symlink usr/lib64 /lib64 \\
  --symlink usr/bin /bin \\
  --ro-bind /usr /usr \\
  --ro-bind /opt /opt \\
  --dev-bind /dev /dev \\
  --ro-bind /sys /sys \\
  --ro-bind /etc/passwd /etc/passwd \\
  --ro-bind /etc/resolv.conf /etc/resolv.conf \\
  --ro-bind /etc/localtime /etc/localtime \\
  --proc /proc \\
  --dev-bind /run/dbus /run/dbus \\
  --bind \"\${USER_RUN_DIR}\" \"\${USER_RUN_DIR}\" \\
  --ro-bind-try /etc/fonts /etc/fonts \\
  --dev-bind /tmp /tmp \\
  --bind-try \"\${HOME}/.pki\" \"\${HOME}/.pki\" \\
  --ro-bind-try \"\${XAUTHORITY}\" \"\${XAUTHORITY}\" \\
  --bind-try \"\${DOWNLOAD_DIR}\" \"\${DOWNLOAD_DIR}\" \\
  --ro-bind-try \"\${CONFIG_HOME}\" \"\${CONFIG_HOME}\" \\
  --bind \"\${QQ_APP_DIR}\" \"\${QQ_APP_DIR}\" \\
  --ro-bind-try \"\${HOME}/.local\" \"\${HOME}/.local\" \\
  --setenv DISPLAY \"\${DISPLAY}\" \\
  /opt/QQ/qq \"\$@\"


""" > ./unpack/usr/bin/linuxqq

chmod +x ./unpack/usr/bin/linuxqq


echo "修正完成, 计算文件md5..."

cd ./unpack

# opt目录中有文件名中带有空格, ;xargs需要处理一下
find opt/ -type f | xargs -I {} md5sum {} > DEBIAN/md5sums
find usr/ -type f | xargs md5sum >> DEBIAN/md5sums

echo """
Package: linuxqq
Version: ${version}
Architecture: amd64
Maintainer: Yutent <yutent.io@gmail.com>
Installed-Size: 412821
Depends: libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6, xdg-utils, libatspi2.0-0, libuuid1, libsecret-1-0
Recommends: libappindicator3-1
Section: chat
Priority: optional
Homepage: https://im.qq.com
Description: linux QQ
""" > DEBIAN/control

echo '计算文件md5完成, 打包中...'

cd ..
sudo chown -R root:root unpack

dpkg-deb -b ./unpack "./${app_name}_${version}.deb"

echo "打包完成 :)"
