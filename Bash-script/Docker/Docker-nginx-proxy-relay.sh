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
#安装nginx-proxy
function install_nginx-proxy(){
docker stop nginx-proxy
docker rm nginx-proxy
sleep 2s
rm -rf /docker/nginx-proxy
mkdir /docker
mkdir /docker/nginx-proxy
mkdir /docker/nginx-proxy/proxy
cat > /docker/nginx-proxy/nginx.conf <<-EOF

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;
include /etc/nginx/proxy/*.conf;

events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}

EOF

######################################
    green "======================="
    blue "请输入要被转发的服务器ip(可以用域名解析)"
    green "======================="
    read fwq_ip
######################################
######################################
    green "======================="
    blue "请输入要被转发的服务器端口号"
    green "======================="
    read fwq_port
######################################
######################################
    green "======================="
    blue "请输入转发后用于连接的端口号"
    blue "注意不要用重复端口号"
    blue "转发完成后用本服务器的IP和这个端口号连接"
    green "======================="
    read fwqproxy_port
######################################
cat > /docker/nginx-proxy/proxy/proxy.conf <<-EOF
stream {
    upstream proxy {
        server $fwq_ip:$fwq_port;              
    }
    server {
        listen 21211;
        listen 21211 udp;
        proxy_pass proxy;
    }
}
EOF
sleep 5s
docker run -d \
    --name nginx-proxy \
    --restart unless-stopped \
    -p $fwqproxy_port:21211\
    -p $fwqproxy_port:21211/udp \
    -v /docker/nginx-proxy/nginx.conf:/etc/nginx/nginx.conf \
    -v /docker/nginx-proxy/proxy/proxy.conf:/etc/nginx/proxy/proxy.conf \
    nginx:stable
green "Nginx-proxy转发完成,请使用本机IP和设置的转发后端口连接"
green "要重新设置请先删除已经运行的容器然后重新安装"
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
    green " 3. 安装nginx-proxy中转代理"
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
    install_nginx-proxy
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
