#!/bin/bash
#=============================================-=============================
  docker -v||(echo "你没有安装docker,无法使用v2ray"&&echo "接下来自动为你安装docker,并启动服务"\
&&wget -N --no-check-certificate "https://raw.githubusercontent.com/vizshrc/AutoTODo/master/docker_install.sh"\
&&sudo chmod +x docker_install.sh&&./docker_install.sh)