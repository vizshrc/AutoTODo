#!/bin/bash
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



#证书没问题则生成配置
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
"|sed '/^#/d;/^\s*$/d' > ./v2ray_nginx.conf


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
        
        proxy_pass http://v2s:${v2port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
}
"|sed '/^#/d;/^\s*$/d' > ./v2ray_nginx.conf
fi


echo_GreenFont "已经生成nginx关于v2ray的配置（v2ray_nginx.conf）,暂存/etc/v2ray/"
}
#=============================================-=============================
config_nginx




