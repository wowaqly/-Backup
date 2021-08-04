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
#安装Docker
function install_docker(){
  apt-get install -y vim unzip git curl
  clear
    echo
    green " 1. 国内服务器"
    green " 2. 国外服务器"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
"registry-mirrors": ["https://7zbtvkwx.mirror.aliyuncs.com","https://dockerhub.azk8s.cn","https://reg-mirror.qiniu.com"]
}
EOF
    systemctl daemon-reload
    systemctl restart docker
    green " Docker已安装"
    ;;
    2)
    curl -fsSL https://get.docker.com | bash -s docker
    green " Docker已安装"
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "Enter the correct number"
    sleep 2s
    start_menu
    ;;
    esac
#更新Docker
}
function update_docker(){
  clear
    green " 1. 国内服务器"
    green " 2. 国外服务器"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    green " Docker已更新"
    ;;
    2)
    rcurl -fsSL https://get.docker.com | bash -s docker
    green " Docker已更新"
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "Enter the correct number"
    sleep 2s
    start_menu
    ;;
    esac
}
#安装frps
function install_heimdall(){
docker stop heimdall
docker rm heimdall
sleep 2s
rm -rf /root/heimdall
cp -rf /docker/heimdall /root
rm -rf /docker/heimdall
mkdir /docker
mkdir /docker/heimdall
mkdir /docker/heimdall/config
cd /docker/heimdall
wget https://raw.githubusercontent.com/wowaqly/Backup/patch/Bash-script/Docker/Heimdall/Search.php
wget https://raw.githubusercontent.com/wowaqly/Backup/patch/Bash-script/Docker/Heimdall/app.php
######################################
    green "======================="
    blue "请输入用于连接的端口号 范围1-65533"
    blue "请注意不要重复使用端口"
    green "======================="
    read portweb
######################################
sleep 5s
docker run -d \
  --name=heimdall \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -p $portweb:80 \
  -v /docker/heimdall/config:/config \
  -v /docker/heimdall/Search.php:/var/www/localhost/heimdall/app/Search.php \
  -v /docker/heimdall/app.php:/var/www/localhost/heimdall/resources/lang/en/app.php \
  --restart unless-stopped \
  ghcr.io/linuxserver/heimdall
green "heimdall安装已完成"
green "如果是重新安装，之前的配置文件已经cp到/root/heimdall中,可以替换/docker/heimdall/config恢复之前的设置"
}
# 说明
function ps_docker(){
 clear
    green " ==============================================="
    green " docker ps -a 命令查看进容器id"
    green " docker stop/restart 容器id ---停止重启容器"
    green " docker rm 容器id ---删除容器---需要先停止容器 "
    green " docker images 命令查看进镜像id"
    green " docker rmi 镜像id ---删除镜像---需要先删除容器 "   
    green " ==============================================="
}
#主菜单
function start_menu(){
    clear
    green " ==============================================="
    green " Info       : onekey script install  filebrowser       "
    green " OS support : debian9+/ubuntu16.04+                       "
    green " 只支持amd64机器 "
    green "Nginx-proxy转发完成后,请使用本机IP和设置的转发后端口连接"
    green "要重新设置请先删除已经运行的容器然后重新安装"
    green " ==============================================="
    echo
    green " 1. 安装Docker"
    green " 2. 更新Docker"
    green " 3. 安装heimdall"
    green " 4. docker停止/重启/删除容器说明"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    install_docker
    ;;
    2)
    update_docker
    ;;
    3)
    install_heimdall
    ;;
    4)
    ps_docker
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

start_menu
