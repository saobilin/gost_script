#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# ====================================================
#	Writer:t.me/saobilin
#	Dscription: GOST一键脚本傻瓜版 WSS/WS/TLS
#	Version: fix auto start in the vps boot
# ====================================================

Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

checkos(){
    if [[ -f /etc/redhat-release ]];then
        OS=CentOS
    elif cat /etc/issue | grep -q -E -i "debian";then
        OS=Debian
    elif cat /etc/issue | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    elif cat /proc/version | grep -q -E -i "debian";then
        OS=Debian
    elif cat /proc/version | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    else
        echo "Not supported OS, Please reinstall OS and try again."
        exit 1
    fi
}
disable_firewall(){
	if [ "${OS}" == 'CentOS' ];then
    systemctl stop firewalld.service >/dev/null 2>&1
    systemctl disable firewalld.service >/dev/null 2>&1
    service iptables stop >/dev/null 2>&1
    chkconfig iptables off >/dev/null 2>&1
	else
	ufw disable
	fi
}

get_ip(){
    ip=`curl ip.sb`
}

install_gost(){
	echo -e "${Green}即将安装Gost${Font}"
	if [ "${OS}" == 'CentOS' ];then
	yum install -y wget curl && wget https://file.saobilin.online/gost.gz && gzip -d gost.gz &&  chmod a+rx gost && mv gost /usr/local/bin/gost && chown root:root /usr/local/bin/gost && wget file.saobilin.online/key.pem && wget file.saobilin.online/cert.pem &&  cp *.pem /usr/local/bin/ &&rm -rf gost && rm -rf *.pem
	 else
	apt-get install -y wget curl && wget https://file.saobilin.online/gost.gz && gzip -d gost.gz && chmod a+rx gost && mv gost /usr/local/bin/gost && chown root:root /usr/local/bin/gost && wget file.saobilin.online/key.pem && wget file.saobilin.online/cert.pem && cp *.pem /usr/local/bin/ && rm -rf gost && rm -rf *.pem
	fi
	if [ -s /usr/local/bin/gost ]; then
	echo -e "${Green}gost安装完成！${Font}"
	fi
									    }
look_gost(){
	if [ -s /usr/local/bin/gost ]; then
	echo -e "${Green}检测到gost已存在，并跳过安装步骤！${Font}"
	config_guonei
	else
	install_gost
	fi
															    }    
status_gost(){
clear
echo -e "${Green}GOST一键脚本${Font}"
echo -e "${Green}1:gost设置(国内端)${Font}"
echo -e "${Green}2:gost设置(国外端)${Font}"
echo -e "${Green}${Font}"
read -e -p "请输入数字:" num
case "$num" in
	1)
	run_guonei
	;;
	2)
    run_guowai
	;;
esac
}
run_guonei(){
checkos
rootness
look_gost
disable_firewall
config_guonei
}
run_guowai(){
checkos
rootness
look_gost
disable_firewall
config_guowai
}  
config_guonei(){
    echo -e "常见模式wss/ws/tls/kcp/sni"
    read -p "请输入gost的工作模式:" gostmode
    read -p "请输入本地TCP端口:" tcp
    read -p "请输入本地UDP端口:" udp 
    read -p "请输入后端IP:" gostip
    read -p "请输入后端接收流量的端口:" gostport
    start_gost_guonei
}
start_gost_guonei(){
    echo -e "${Red}正在配置Gost_${gostmode}...${Font}"
    if [ "${OS}" == 'CentOS' ];then
    sed -i '/exit/d' /etc/rc.d/rc.local
	nohup  gost -L=tcp://:${tcp} -L=udp://:${udp} -F=relay+${gostmode}://${gostip}:${gostport} >> /dev/null 2>&1 &
	echo "nohup  gost -L=tcp://:${tcp} -L=udp://:${udp} -F=relay+${gostmode}://${gostip}:${gostport} >> /dev/null 2>&1 &" >>  /etc/rc.local
	chmod +x  /etc/rc.local
    elif [ -s /etc/rc.local ]; then
    sed -i '/exit/d' /etc/rc.local
    nohup  gost -L=tcp://:${tcp} -L=udp://:${udp} -F=relay+${gostmode}://${gostip}:${gostport} >> /dev/null 2>&1 &
	echo "nohup  gost -L=tcp://:${tcp} -L=udp://:${udp} -F=relay+${gostmode}://${gostip}:${gostport} >> /dev/null 2>&1 &" >> /etc/rc.local
    chmod +x  /etc/rc.local
    else
    echo -e "${Green}检测到系统无rc.local自启，正在为其配置... ${Font} "
echo "[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
 
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
 
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/rc-local.service
echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
" > /etc/rc.local
echo "nohup  gost -L=tcp://:${tcp} -L=udp://:${udp} -F=relay+${gostmode}://${gostip}:${gostport} >> /dev/null 2>&1 &
" >> /etc/rc.local
chmod +x /etc/rc.local
systemctl enable rc-local >/dev/null 2>&1
systemctl start rc-local >/dev/null 2>&1
    fi
    get_ip
    sleep 3
    echo
    echo -e "${Green}Gost ${gostmode}段安装并配置成功!${Font}"
    echo -e "${Blue}你的本地TCP端口为:${tcp}${Font}"
    echo -e "${Blue}你的本地UDP端口为:${udp}${Font}"
    echo -e "${Blue}你的远程后端端口为:${gostport}${Font}"
    echo -e "${Blue}你的本地服务器IP为:${ip}${Font}"
    exit 0
}
config_guowai(){
    echo -e "${Green}请输入国外端配置信息！${Font}" 
    read -p "请输入gost的工作模式:" gostmode
    read -p "请输入接收流量的端口:" report
    read -p "请输入要转发的ip(不填写默认本地):" gostip
    read -p "请输入要转发的端口:" proxyport
    start_guowai
}
start_guowai(){
 echo -e "${Green}正在配置Gost_${gostmode}...${Font}"
    if [ "${OS}" == 'CentOS' ];then
    yum install screen -y
    else
    apt install screen -y
    fi
     if [ "${OS}" == 'CentOS' ];then
    sed -i '/exit/d' /etc/rc.d/rc.local
	nohup gost -L=relay+${gostmode}://:${report}/${gostip}:${proxyport} >> /dev/null 2>&1 &
    echo "nohup gost -L=relay+${gostmode}://:${report}/${gostip}:${proxyport} >> /dev/null 2>&1 &" >> /etc/rc.local
    chmod +x /etc/rc.local
    elif [ -s /etc/rc.local ]; then
    sed -i '/exit/d' /etc/rc.local
    nohup gost -L=relay+${gostmode}://:${report}/${gostip}:${proxyport} >> /dev/null 2>&1 &
    echo "nohup gost -L=relay+${gostmode}://:${report}/${gostip}:${proxyport} >> /dev/null 2>&1 &" >> /etc/rc.local
    chmod +x /etc/rc.local
    else
    echo -e "${Green}检测到系统无rc.local自启，正在为其配置... ${Font} "
echo "[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
 
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
 
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/rc-local.service
echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
" > /etc/rc.local
echo "nohup gost -L=relay+${gostmode}://:${report}/${gostip1}:${proxyport} >> /dev/null 2>&1 &
" >> /etc/rc.local
chmod +x /etc/rc.local
systemctl enable rc-local >/dev/null 2>&1
systemctl start rc-local >/dev/null 2>&1
    fi
	get_ip
    sleep 1
    echo
    echo -e "${Green}Gost ${gostmode} 端安装并配置成功!${Font}"
    echo -e "${Blue}你的本地接收端口为:${report}${Font}"
    echo -e "${Blue}你的转发端口为:${proxyport}${Font}"
    echo -e "${Blue}你的转发ip为:${gostip}${Font}"
    echo -e "${Blue}你的本地服务器IP为:${ip}${Font}"
    exit 0
}
status_gost