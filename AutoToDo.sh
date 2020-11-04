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
rm -f *AutoTODo*&&rm -f *docker_install* &&rm -f *v2ray_docker*&&rm -f ./*.sh



MENU_1=(1.退出脚本 2.更新脚本 3.安装docker 4.安装v2ray)
select choice in ${MENU_1[@]};do
	case $choice in
		1.退出脚本 )
			echo_YellowFont "您选择的是${choice}"
			echo_GreenFont "已退出脚本"

			break
			;;
		2.更新脚本 )
#更新脚本的思路是先下载已更新的版本并赋权执行，
#break表示这个操作之后结束循环，在这里等于退出了当前的脚本

			#删除
			rm -f ./AutoTODo.sh\
			&&wget -N --no-check-certificate "https://raw.githubusercontent.com/vizshrc/AutoTODo/master/AutoTODo.sh"&&echo_GreenFont "脚本已更新，请选择接下来的操作"&&chmod +x AutoTODo.sh&&./AutoTODo.sh			
			break
			;;
		3.安装docker )
			echo_YellowFont "您选择的是安装docker"
			wget --no-check-certificate --content-disposition "https://raw.githubusercontent.com/vizshrc/AutoTODo/master/docker_install.sh"&&chmod +x docker_install.sh&&bash ./docker_install.sh

			 break
			 ;;


		4.安装v2ray )
			echo_YellowFont "您选择的是安装v2ray"
			wget --no-check-certificate --content-disposition "https://raw.githubusercontent.com/vizshrc/AutoTODo/master/v2ray_docker.sh"&&chmod +x v2ray_docker.sh&&./v2ray_docker.sh
			break
			;;
#github连接以前不用冒号，现在必须得！		
		*)
			echo "选项错误"
			exit 2
	esac
done