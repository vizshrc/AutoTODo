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

#移动配置文件
if [[ -f /etc/v2ray ]]; then
  mv config.json /etc/v2ray&&echo_GreenFont "配置已经生成并在位于/etc/v2ray中"
else mkdir -p /etc/v2ray&&mv config.json /etc/v2ray\
  &&echo_GreenFont "配置已经生成并在位于/etc/v2ray中"
fi
#======================================================================
#检查是否安装了docker,否则无法启动v2ray容器
check_dockerInstall(){
  docker -v||echo_RedFont "你没有安装docker,无法使用v2ray"\
&&echo_GreenFont "接下来自动为你安装docker,并启动服务"\
&&wget -N --no-check-certificate "https://raw.githubusercontent.com/vizshrc/AutoTODo/master/docker_install.sh"\
&&sudo chmod +x docker_install.sh&&./docker_install.sh
}

#======================================================================
config_v2
check_dockerInstall
docker run -d --name v2ray -v /etc/v2ray:/etc/v2ray -p 127.0.0.1:10101:443 v2ray/official  v2ray -config=/etc/v2ray/config.json||echo_RedFont "请检查失败！"

