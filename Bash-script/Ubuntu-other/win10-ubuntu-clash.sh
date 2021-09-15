#!/bin/bash
function blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
function green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
function red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
function yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
#主菜单
function start_menu(){
    clear
    green " ==============================================="
    green " 只支持win10-linux子系统的Ubuntu版本 "
    green " 必须使用root权限执行" 
    green " clash配置文件在/root/.config/clash  替换后修改congif.yaml"
    green " 用脚本更新clash配置文件，把文件放到c盘ubuntu/clash，并重命名为congif.yaml后执行"
    green " 更新clash去https://github.com/Dreamacro/clash/releases/tag/premium下载最新版本解压后传到自己的GitHub中"
    green " 更新控制台去https://github.com/Dreamacro/clash-dashboard/archive/refs/heads/gh-pages.zip下载最新版本解压重后重新打包为yacd.zip传到自己的GitHub中 "
    green " 备用控制台https://github.com/haishanh/yacd/releases "
    green " ==============================================="
    echo
    green " 1. 启动/重启Clash"
    green " 2. 关闭Clash"
    green " 3. 更新Clash-config"
    green " 4. 更新Clash"
    green " 5. 安装Clash"
	green " 6. 更换国内源"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    start_clash
    ;;
    2)
    stop_clash
    ;;
    3)
    update_clash_config
    ;;
    4)
    update_clash
    ;;
    5)
    install_clash
    ;;
    6)
    update_apt
    ;;
    0)
    exit
    ;;
    *)
    clear
    red "Enter the correct number"
    sleep 2s
    start_menu
    ;;
    esac
}
#更换国内源
function update_apt(){
    sudo cp -f /etc/apt/sources.list /etc/apt/sources.list.beifeng
    sudo rm -f /etc/apt/sources.list
sudo bash -c 'cat << EOF > /etc/apt/sources.list
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF'
    sudo apt update
	sudo apt upgrade 
	green " 源已更新"
}
#安装Clash
function install_clash(){
	apt install nginx vim unzip wget upx -y
        cd /root
	mkdir clash
	cd /root/clash
	wget https://raw.outlink.top/wowaqly/Backup/patch/App/Clash/clash-linux-amd64
	chmod +x clash-linux-amd64
	upx --brute clash-linux-amd64 -o pogo
	rm -f clash-linux-amd64
	chmod +x pogo
	rm -rf /var/www/html/*
	cd /var/www/html
	wget https://raw.outlink.top/wowaqly/Backup/patch/App/Clash/yacd.zip
	unzip yacd.zip
	rm -f yacd.zip
	green " clash 已安装"
}
#更新Clash
function update_clash(){
	cd /root/clash
	rm -f pogo
	wget https://raw.outlink.top/wowaqly/Backup/patch/App/Clash/clash-linux-amd64
	chmod +x clash-linux-amd64
        upx --brute clash-linux-amd64 -o pogo
	rm -f clash-linux-amd64
	chmod +x pogo
	cd /var/www/html
	rm -rf /var/www/html/*
	wget https://raw.outlink.top/wowaqly/Backup/patch/App/Clash/yacd.zip
	unzip yacd.zip
	rm -f yacd.zip
	green " clash 已更新"
}
#启动Clash
function start_clash(){
    killall -9 nginx 
    killall -9 pogo
    cd /root/.config/clash
    rm -f Country.mmdb
    wget https://raw.outlink.top/Hackl0us/GeoIP2-CN/release/Country.mmdb
    nginx
    cd /root/clash
    nohup ./pogo &
}
#关闭Clash
function stop_clash(){
    killall -9 nginx 
    killall -9 pogo
}
#更新config
function update_clash_config(){
    killall -9 nginx 
    killall -9 pogo
	rm -f /root/.config/clash/config.yaml
	cp /mnt/c/ubuntu/clash/config.yaml /root/.config/clash
}
start_menu
