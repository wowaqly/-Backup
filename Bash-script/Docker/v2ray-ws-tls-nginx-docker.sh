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

function check_os(){
green "系统支持检测"
sleep 3s
if   cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
fi
if [ "$release" == "ubuntu" ]; then
    if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
    red "==============="
    red "当前系统不受支持"
    red "==============="
    exit
    fi
    if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
    red "==============="
    red "当前系统不受支持"
    red "==============="
    exit
    fi
    ufw_status=`systemctl status ufw | grep "Active: active"`
    if [ -n "$ufw_status" ]; then
        ufw allow 80/tcp
        ufw allow 443/tcp
    fi
    apt-get update
    apt-get install -y jq git curl vim openssl
elif [ "$release" == "debian" ]; then
    apt-get update 
    apt-get install -y jq git curl vim openssl
fi
}
#安装环境监测
function check_env(){
green "安装环境监测"
sleep 3s
firewall_status=`firewall-cmd --state`
if [ "$firewall_status" == "running" ]; then
    green "检测到firewalld开启状态，添加放行80/443端口规则"
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-port=443/tcp --permanent
    firewall-cmd --reload
fi
$systemPackage -y install net-tools socat >/dev/null 2>&1
Port80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
Port443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`
if [ -n "$Port80" ]; then
    process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
    red "==========================================================="
    red "检测到80端口被占用，占用进程为：${process80}，本次安装结束"
    red "==========================================================="
    exit 1
fi
if [ -n "$Port443" ]; then
    process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
    red "============================================================="
    red "检测到443端口被占用，占用进程为：${process443}，本次安装结束"
    red "============================================================="
    exit 1
fi
}
#start_install
function start_install(){
    green "======================="
    blue "请输入绑定到本VPS的域名"
    blue " 如果你的域名已经添加过Cloudflare的cdn，需要先去取消cdn(小黄云），安装完成后再打开cdn(小黄云) "
    green "======================="
    read your_domain
    real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
    local_addr=`curl ipv4.icanhazip.com`
    if [ $real_addr == $local_addr ] ; then
    green "=========================================="
	green "         域名解析正常，开始安装"
	green "=========================================="
        install_v2ray_nginx
    else
    red "===================================="
	red "域名解析地址与本VPS IP地址不一致"
	red "若你确认解析成功你可强制脚本继续运行"
	red "===================================="
	read -p "是否强制运行 ?请输入 [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
            green "强制继续运行脚本"
	    sleep 1s
	    install_v2ray_nginx
	else
	    exit 1
	fi
    fi
}

#install_v2ray_nginx
function install_v2ray_nginx(){
    curl -fsSL https://get.docker.com | bash -s docker
    docker stop nginx
    docker stop v2ray
    docker stop acme
    docker rm nginx
    docker rm v2ray
    docker rm acme
    docker network rm v2raynetwork
    docker network create --subnet=192.1.1.0/24 v2raynetwork
    rm -rf /v2ray
    mkdir /v2ray
    mkdir /v2ray/nginx
    mkdir /v2ray/acme
    mkdir /v2ray/v2ray
newpath=$(cat /dev/urandom | head -1 | md5sum | head -c 9)
v2uuid=$(cat /proc/sys/kernel/random/uuid)
    green "======================="
    blue "如果是使用了cloduflare works的反代，需要去/v2ray/nginx/default.conf把error_page 400 = 后面的网址改成反代后的网址,然后重启docker nginx"
    green "======================="
    sleep 3s
cat > /v2ray/nginx/default.conf<<-EOF
server { 
    listen       80;
    server_name  $your_domain;
    rewrite ^(.*)$  https://\$host\$1 permanent; 
}
server {
    listen 443 ssl http2;
    server_name $your_domain;
    error_page 400 = https://$your_domain;
    location / {
        proxy_pass http://192.1.1.15:32400;
    }
    ssl_certificate /home/fullchain.cer; 
    ssl_certificate_key /home/$your_domain.key;
    #TLS 版本控制
    ssl_protocols TLSv1.3;
    #如果要使用TLSv1.2,请在上一行的TLSv1.3前面加入TLSv1.2
    #  1.3 0-RTT
    ssl_early_data off;
    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security "max-age=31536000";
    #access_log /var/log/nginx/access.log combined;
    #v2ray
    location /$newpath {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:12345; 
	    client_max_body_size 0;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        # Show real IP in v2ray access.log
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
cat > /v2ray/v2ray/config.json<<-EOF
{
  "log" : {
    "access": "/access.log",
    "error": "/error.log",
    "loglevel": "warning"
  },
  "inbound": {
    "port": 12345,
    "listen":"127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$v2uuid",
          "alterId": 64
        }
      ]
    },
     "streamSettings": {
      "network": "ws",
      "wsSettings": {
     	 "path": "/$newpath"
    	}
     }
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  }
}
EOF
docker run -d  \
  -itd \
  --restart=always \
  -v /v2ray/acme/conf:/acme.sh  \
  -v /v2ray/acme/ssl:/nginx-ssl \
  --net=host \
  --name=acme \
  neilpang/acme.sh daemon
docker exec acme --set-default-ca  --server  letsencrypt
docker exec acme --issue  -d $your_domain  --standalone
docker exec acme mkdir /nginx-ssl
docker exec acme --install-cert -d  $your_domain   \
        --key-file   /nginx-ssl/$your_domain.key \
        --fullchain-file /nginx-ssl/fullchain.cer
        
docker run -d \
  --restart=always \
  --name v2ray \
  --network=v2raynetwork \
  --ip 192.1.1.13 \
  -p 127.0.0.1:12345:12345 \
  -p 127.0.0.1:12345:12345/udp \
  -v /v2ray/v2ray/config.json:/etc/v2ray/config.json \
  v2fly/v2fly-core

docker run \
  -d \
  --network=v2raynetwork \
  --ip 192.1.1.15 \
  --name plex \
  --restart=always \
  -v /docker/plex:/data \
  plexinc/pms-docker
  
docker run -d \
  --restart=always \
  --name nginx \
  -v /v2ray/nginx/default.conf:/etc/nginx/conf.d/default.conf \
  -v /v2ray/acme/ssl:/home \
  --net=host \
  nginx
  
 }
check_os 
check_env
start_install