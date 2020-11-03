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

select location_vps in 1.国外 2.国内 ;do
	case $location_vps in
		1.国外 )
			curl -fsSL https://get.docker.com | bash -s docker
			docker -v&&echo_GreenFont "docker已经就绪"||echo_RedFont "请检查出错"
			
			break
			;;
		2.国内 )
			curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
			docker -v&&echo_GreenFont "docker已经就绪"||echo_RedFont "请检查出错"
			
			break
			;;
	esac
done