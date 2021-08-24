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
#安装nginx反代
function install_nginx_proxy(){
######################################
    green "======================="
    green "此脚本只适用于反代套过cloud flare的cdn的https网站,并且需要最低TLS版本为1.2"
    green "此脚本只适用于反代套过cloud flare的cdn的https网站,并且需要最低TLS版本为1.2"
    green "此脚本只适用于反代套过cloud flare的cdn的https网站,并且需要最低TLS版本为1.2"
    green "在cloud flare的域名管理的SSL/TLS中把最低TLS版本改为1.2"
    blue "请先把证书和密钥放到/root/nginx中"
    blue "如果没有放请clrt c结束安装"
    blue "sleep 20s"    
    green "======================="
######################################
sleep 20s
docker stop nginx
docker rm nginx
sleep 2s
rm -rf /docker/nginx
mkdir /docker
mkdir /docker/nginx
mkdir /docker/nginx/conf.d
mkdir /docker/nginx/ssl
cp /root/nginx/*.* /docker/nginx/ssl
######################################
    green "======================="
    blue "请输入用来中转/反代的域名"
    blue "不需要https http这种前缀"
    green "======================="
    read myserver
######################################
######################################
    green "======================="
    blue "请输入中转/反代后用于连接的端口"
    blue "不要用以在使用的端口"    
    green "======================="
    read myport
######################################
######################################
    green "======================="
    blue "请输入接入cloudflare cdn/被反代的域名"
    blue "不需要https http这种前缀"
    green "======================="
    read proxyserver
######################################
######################################
    green "======================="
    blue "请输入证书的名字"
    blue "需要带有后缀 crt 或 pem"
    green "======================="
    read sslpem
######################################
######################################
    green "======================="
    blue "请输入证书key的名字"
    blue "需要带有后缀key"
    green "======================="
    read sslkey
######################################
sleep 5s
cat > /docker/nginx/conf.d/default.conf<<-EOF
server
{
	listen 443 ssl http2;
    server_name $myserver;
    error_page 400 = $myserver;
    
    #SSL-START SSL相关配置，请勿删除或修改下一行带注释的404规则
    #error_page 404/404.html;
    ssl_certificate    /etc/nginx/ssl/$sslpem;
    ssl_certificate_key    /etc/nginx/ssl/$sslkey;
    ssl_protocols TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    add_header Strict-Transport-Security "max-age=31536000";
    error_page 497  https://\$host\$request_uri;
    #SSL-END
 location  ~* \.(php|jsp|cgi|asp|aspx)$
{
    proxy_pass https://$proxyserver;
    proxy_set_header Host $proxyserver;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header REMOTE-HOST \$remote_addr;
    proxy_ssl_name $proxyserver;
    proxy_ssl_server_name on;
}
 location / {
        # 由于我们反代的cloudflare使用的是 https，所以我们需要指明sni，不然是无法握手的，另外还需要设置host，这两个都要设置成接入cloudflare的域名。
        proxy_ssl_name $proxyserver;
        proxy_ssl_server_name on;
        proxy_set_header Host $proxyserver;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_redirect off;
        # 重点！由于我们接入cloudflare的域名和我们反代服务器的域名不一样，typecho的数据库里面记录的链接都是cdn.example.com的形式，所以我们要做内容替换。我们还需要通过设置Accept-Encoding "";来告诉服务器不要对内容进行压缩，不然返回的数据没办法使用sub_filter替换。 
        proxy_set_header Accept-Encoding "";
        sub_filter "https://$proxyserver" "https://$myserver";
        # 开启内容多次替换
        sub_filter_once off;
        # 禁用缓存 （这个应该会影响到cloudfalre的缓存，不建议设置）
        add_header Cache-Control no-cache;
        expires 12h;
        # proxy_pass也可以找个速度快的cloudflare的ip填进去，记得要带https://
        proxy_pass https://$proxyserver;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        }
}
EOF
sleep 3s
 docker  run -d \
  --name nginx \
  -v /docker/nginx/conf.d:/etc/nginx/conf.d \
  -v /docker/nginx/ssl:/etc/nginx/ssl \
  --restart unless-stopped \
  -p $myport:443 \
  nginx

green "nginx-proxy安装已完成"
green "如果要更换配置直接重新安装即可"
green "如果速度特别慢，可以去修改/docker/nginx/conf.d/default.conf中最后的proxy_pass，找个速度快的cloudflare的ip填进去"
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
    green "此脚本只适用于反代套过cloud flare的cdn的https网站"
    green "要重新设置请先删除已经运行的容器然后重新安装"
    green "请先把网站证书和密钥放到/root/nginx中"
    green "sni需要设定成反代后的域名"
    green " ==============================================="
    echo
    green " 1. 安装Docker"
    green " 2. 更新Docker"
    green " 3. 安装nginx-proxy-cloudflare"
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
    install_nginx_proxy
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
