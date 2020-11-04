#!/bin/bash
#检查脚本是否适用于当前系统
check_distribution() {
        lsb_dist=""
        # Every system that we officially support has /etc/os-release
        if [ -r /etc/os-release ]; then
                lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        # Returning an empty string here should be alright since the
        # case statements don't act unless you provide an actual value
        echo "你的系统是$lsb_dist"

        #对适用发行版本的处理（定义包管理器命令）
        ##为了好看(习惯了debian)，所以包管理器的变量名就为apt,即${apt}
        case ${lsb_dist} in
        "debian") apt=apt-get;;
        "ubuntu") apt=apt-get;;
        "centos") apt=yum;;  
        esac 

        #对不适用发行版本的处理（退出脚本）
        #安装前确认系统符合与否
        if [[ ${apt} != "apt-get" ]] && [[ ${apt} != "yum" ]] ; then 
          echo_RedFont "你的系统不是debian、ubuntu或centos,不能使用该脚本安装相应的服务(docker、v2ray、nginx)"\
          &&exit 1
        fi
}
#======================================================================
  #2.优化shell脚本，设置Font_color,注意只能在使用echo时使用
echo_GreenFont(){
  #一般标志succeed
  echo -e "\033[32m$1\033[0m"
}
echo_RedFont(){
  #一般代表Error
  echo -e "\033[31m$1\033[0m"
}
echo_YellowFont(){
  #一般意味warn
  echo -e "\033[33m$1\033[0m"
}
#======================================================================
#检查是否安装了docker,否则无法启动v2ray容器
check_dockerInstall(){
  docker -v||(echo_RedFont "你没有安装docker,无法使用v2ray"&&echo_GreenFont "接下来自动为你安装docker,并启动服务"\
&&wget -N --no-check-certificate "https://raw.githubusercontent.com/vizshrc/AutoTODo/master/docker_install.sh"\
&&sudo chmod +x docker_install.sh&&./docker_install.sh)
}

#======================================================================
#1.生成v2的启动配置 写成函数config_v2方便调用
#变量一览
#v2port v2的inbounds
#v2UUID 出于安全随机生成
#v2Path 即nginx分流（到v2）的标识
config_v2(){

#读入并检查端口合法性
check_port(){
read -e -p "请定义v2的inbound端口[1~65556]:" v2port\
&& [[ ${v2port} -lt 1 ]] || [[ ${v2port} -gt 65535 ]]\
&& echo_RedFont "端口错误请重新输入"&& check_port
};check_port
echo "========================"


#-z 字符串为"null",即是指字符串长度为零
echo -e "请定义v2通信的UUID(建议随机)"
		read -e -p "(默认:随机生成):" v2UUID
		[[ -z "${v2UUID}" ]] && v2UUID=$(uuidgen)


echo "========================"
echo -n "请定义path"
    read -e -p "(默认/ray):" v2path
    [[ -z "${v2path}" ]] && v2path="/ray"

echo "
{
  \"inbounds\": [
    {
      \"port\":${v2port},
      \"listen\":\"0.0.0.0\",//不能只监听 127.0.0.1本地，需要让别的容器探测到开放了端口
      \"protocol\": \"vmess\",
      \"settings\": {
        \"clients\": [
          {
            \"id\": \"${v2UUID}\",
            \"alterId\": 64
          }
        ]
      },
      \"streamSettings\": {
        \"network\": \"ws\",
        \"wsSettings\": {
        \"path\": \"${v2path}\"
        }
      }
    }
  ],
  \"outbounds\": [
    {
      \"protocol\": \"freedom\",
      \"settings\": {}
    }
  ]
}
"|sed '/^#/d;/^\s*$/d' > config.json
echo_GreenFont "已经生成v2ray的启动配置（config.json）"
}



#====================================================================

#2.函数config_nginx:生成docker nignx的转发配置
#ssl 默认是使用acme.sh申请的letsencrypt的证书的地址
#如果不是，则选择自定义ssl_certificate和ssl_certificate_key
#所以两个echo看情况生成配置
#######变量一览
#v2web 伪装的网页地址
#check_sslpath 向用户确认是否可以使用默认的ssl证书路径
#v2path 上面config_v2中已定义，这里跟随 
##选择自定ssl证书路径时，增加ssl_certificate、ssl_certificate_key
#userHOMEpath 用户主目录确定，方便在配置文件中灵活变动
config_nginx(){
echo -n "输入你的v2伪装网址:";read v2web
#检查v2path是否有在config_v2中定义（如选择只生成nginx配置时，需本函数内生成）
[[ -z "${v2path}" ]] && read -e -p "（未定义path,请先定义）:" v2path

echo -e "ssl证书是否用acme.sh申请的【ecc】证书？且位于/root/.acme目录下？"
  read -e -p "(默认：yes):" check_sslpath
  [[ -z "${check_sslpath}" ]] && check_sslpath="yes"
if [[ ${check_sslpath} == "yes" ]] ; then


#必须检查证书是否存在
#那么你的证书路径是/root/.acme.sh/${v2web}_ecc/${v2web}.cer
  if [[ -f /root/.acme.sh/${v2web}_ecc/${v2web}.cer ]]\
    && [[ -f /root/.acme.sh/${v2web}_ecc/${v2web}.key ]] ; then
      echo "证书路径正确"
  else
    echo_RedFont "未找到证书，请检查证书路径是否有误并重新配置（手动输入路径）"&&exit 1
  fi

#证书没问题则生成配置
#userHOMEpath用户主目录
userHOMEpath = eh
echo "
server {
  listen 0.0.0.0:443 ssl;
  ssl_certificate       ${HOME}/.acme.sh/${v2web}_ecc/${v2web}.cer;
  ssl_certificate_key   ${HOME}/.acme.sh/${v2web}_ecc/${v2web}.key;
  ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers           HIGH:!aNULL:!MD5;
  server_name           ${v2web};

##
  root   /var/www/${v2web};
  index  index.php index.html index.htm;
##
        location ${v2path} { # 与 V2 配置中的 path 保持一致
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${v2port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
}
"|sed '/^#/d;/^\s*$/d' > /etc/v2ray_nginx.conf


##如果ssl证书地址有变则自定义
else
  echo -e "请输入你的ssl_certificate路径"
  read -e -p "例如/root/.acme.sh/web.com/web.com.cer :" ssl_certificate
  echo
  echo -e "请输入你的ssl_certificate_key路径"
  read -e -p "例如/root/.acme.sh/web.com/web.com.key :" ssl_certificate_key
  #开始检查证书,不合法直接退出
    if [[ -f ${ssl_certificate} ]] && [[ -f ${ssl_certificate} ]] ; then
      echo "证书路径正确"
    else
      echo_RedFont "未找到证书，请检查证书路径是否有误并重新配置"&&exit 1
    fi

  echo "
server {
  listen 0.0.0.0:443 ssl;
  ssl_certificate       ${ssl_certificate};
  ssl_certificate_key   ${ssl_certificate_key};
  ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers           HIGH:!aNULL:!MD5;
  server_name           ${v2web};

##这里说明网站地址
  root   /var/www/${v2web};
  index  index.php index.html index.htm;


#下面是v2ray
        location ${v2path} { # 与 V2Ray 配置中的 path 保持一致
        proxy_redirect off;
        
        proxy_pass http://127.0.0.1:${v2port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
}
"|sed '/^#/d;/^\s*$/d' > /etc/v2ray/v2ray_nginx.conf
fi


echo_GreenFont "已经生成nginx关于v2ray的配置（v2ray_nginx.conf）,暂存/etc/v2ray/"
}


#=============================================-=============================
#=============================================-=============================
#启动服务
start_service(){

#移动v2ray配置文件到/etc/v2ray
if [[ -f /etc/v2ray ]]; then
  mv config.json /etc/v2ray&&echo_GreenFont "v2ray配置文件config.json已经在/etc/v2ray中就绪"
else mkdir -p /etc/v2ray&&mv config.json /etc/v2ray\
  &&echo_GreenFont "v2ray配置文件config.json已经在/etc/v2ray中就绪"
fi
  
#1.nginx
nginx -v||${apt} install nginx
cp /etc/v2ray/v2ray_nginx.conf /etc/nginx/conf.d/v2ray_nginx.conf&&service nginx restart||echo_RedFont "nginx重启失败检查出错" 
#2.v2ray_docker
docker run -d --name v2ray -v /etc/v2ray:/etc/v2ray -p 127.0.0.1:${v2port}:${v2port} v2ray/official  v2ray -config=/etc/v2ray/config.json||echo_RedFont "请检查失败！"

}
#=============================================-=============================

#输出必要信息一览表
view_info(){
  echo -e "==============================================="
  [[ ${need_v2} == "yes" ]] && echo_GreenFont "
  v2客户端连接信息
  类型：VMess
  地址：${v2web}
  端口：443
  UUID：${v2UUID}
  类型：ws
  路径(URL):${v2path}
  TLS:1（打开）
  "
}
#=============================================-=============================

#主程序来了
check_distribution
check_dockerInstall
config_v2
config_nginx
start_service
view_info






