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


MENU_1=(1.退出脚本 2.更新脚本 3.进入菜单)
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
			sudo chmod +x AutoToDo.sh&&./AutoToDo.sh&&echo_GreenFont "脚本已更新，请选择接下来的操作"
			break
			;;
		3.安装docker )
			echo_YellowFont "您选择的是安装docker"
			wget -N --no-check-certificate \
			"https://raw.githubusercontent.com/vizshrc/AutoTODo/master/docker_install.sh"\
			&&sudo chmod +x docker_install.sh&&./docker_install.sh
			break
			;;
#github连接以前不用冒号，现在必须得！		
		*)
			echo "选项错误"
			exit 2
	esac
done


# MENU_2=(1.安装docker 2.docker安装v2ray 3.dcoker安装qbitrrent)
# select MENU_ITEM in ${MENU_ITEMS[@]}
# do echo "好的"
# break
# done

#!/bin/bash
# select choice in 1yuan 2yuan 5yuan Quit ;do 
#     case $choice in
#         1yuan)
#             echo "You can buy a glass of water "
#             ;;  
#         2yuan)
#             echo "You can buy  an ice cream "
#             ;;  
#         5yuan)
#             echo "You can buy  a chicken leg "
#             echo "Choice $REPLY" 
#             ;;  
#         Quit)
#             echo "Bye"
#             break
#             ;;  
#         *)  
#             echo "Enter error!"
#             exit 2
     
#     esac
# done