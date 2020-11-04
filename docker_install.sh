#!/bin/bash
check_root(){
  [[ $EUID != 0 ]] && echo_RedFont "
  安装docker需要ROOT用户，当前没有ROOT权限！\
  " && exit 1
}
check_distribution() {
        lsb_dist=""
        # Every system that we officially support has /etc/os-release
        if [ -r /etc/os-release ]; then
                lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        # Returning an empty string here should be alright since the
        # case statements don't act unless you provide an actual value
        echo_YellowFont "您的系统是$lsb_dist"

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
locaton_select(){
  select location_vps in 1.国外 2.国内 ;do
  case $location_vps in
    1.国外 )
#错误则需要sudo包，2>1&重定向错误信息 丢弃
      (sudo -h >> /dev/null 2>&1) || ${apt} install sudo
      (curl -h >> /dev/null 2>&1) || ${apt} install curl
      curl -fsSL https://get.docker.com | bash -s docker
      docker -v&&echo_GreenFont "docker已经就绪"||echo_RedFont "请检查出错"
      
      break
      ;;
    2.国内 )
      (sudo -h >> /dev/null 2>&1) || ${apt} install sudo
      (curl -h >> /dev/null 2>&1) || ${apt} install curl
      curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
      docker -v&&echo_GreenFont "docker已经就绪"||echo_RedFont "请检查出错"
      
      break
      ;;
  esac
done
}
#======================================================================
check_root
check_distribution
locaton_select

