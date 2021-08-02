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
function install_frps(){
docker stop frps
docker rm frps
sleep 2s
rm -rf /docker/frps
mkdir /docker
mkdir /docker/frps
######################################
    green "======================="
    blue "请输入用于连接的端口号 范围1-65533"
    blue "请注意不要重复使用端口"
    green "======================="
    read frps_bind_port
######################################
    green "======================="
    blue "请输入用于连接的密码"
    green "======================="
    read frps_token
######################################
    green "======================="
    blue "请输入用于web管理界面的端口号 范围1-65533"
    blue "请注意不要重复使用端口"
    green "======================="
    read frps_dashboard_port
######################################
    green "======================="
    blue "请输入用于web管理界面的用户名"
    green "======================="
    read frps_dashboard_user
######################################
    green "======================="
    blue "请输入用于web管理界面的密码"
    green "======================="
    read frps_dashboard_pwd
###################################### 
    green "======================="
    blue "请输入用于反代http服务的端口号 范围1-65533 "
    blue "请注意不要重复使用端口"
    green "======================="
    read frps_vhost_http_port
###################################### 
    green "======================="
    blue "请输入用于反代https服务的端口号 范围1-65533 "
    blue "请注意不要重复使用端口"
    green "======================="
    read frps_vhost_https_port
######################################
    green "======================="
    blue "请输入frps服务器绑定的域名,例如frp.xxx.com"
    blue "这里一定要加入前缀，不可直接输入xxx.com!!!"
    green "======================="
    read frps_subdomain_host
######################################
cat > /docker/frps/frps.ini <<-EOF
[common]
bind_port = $frps_bind_port
kcp_bind_port = $frps_bind_port
token = $frps_token
authentication_timeout = 900
dashboard_port = $frps_dashboard_port
dashboard_user = $frps_dashboard_user
dashboard_pwd = $frps_dashboard_pwd
vhost_http_port = $frps_vhost_http_port
vhost_https_port = $frps_vhost_https_port
subdomain_host = $frps_subdomain_host
tls_only = true
EOF
sleep 5s
docker run --restart=always --network host -d -v /docker/frps/frps.ini:/etc/frp/frps.ini --name frps snowdreamtech/frps
green "Frps安装已完成"
green "要修改配置可以直接重装一遍，或者修改/docker/frps/frps.ini后重启容器"
}
#安装frpc
function install_frpc(){
    green "======================="
    blue "现在/root下编辑好/root/frpc.ini再运行！！"
    blue "如果没有编辑的现在按ctrl+c退出安装"
    blue "sleep 20s"
    green "======================="
    sleep 20s
    docker stop frpc
    docker rm frpc
    sleep 2s
    rm -rf /docker/frpc
    mkdir /docker
    mkdir /docker/frpc
    cp /root/frpc.ini /docker/frpc
    docker run --restart=always --network host -d -v /docker/frpc/frpc.ini:/etc/frp/frpc.ini --name frpc snowdreamtech/frpc
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
    green " 3. 安装frps"
    green " 3. 安装frpc----请先在/root下配置/root/frpc.ini"
    green " 5. docker停止/重启/删除容器说明"
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
    install_frps
    ;;
    4)
    install_frpc
    ;;
    5)
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
