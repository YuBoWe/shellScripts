#!/bin/bash

# 参数
PWD=123456
END=254
HOST=10.0.0
ONE=3
DIR=/data/
ACTIVE_FILE=${DIR}/active.log
OS=$(sed -rn '/^NAME=/p' /etc/os-release | awk -F'[ ="]+' '{print $2}')

# 准备
prepare(){
	if [ -e $DIR ];then
		if [ -e $ACTIVE_FILE ];then
			rm -f $ACTIVE_FILE
		fi
	else
		mkdir $DIR
	fi
	if [ $OS = 'Ubuntu' ];then
		apt-get install -y expect &> /dev/null || { echo "expect安装失败，请检查网络";exit 1; }
	elif [ $OS = 'Centos' ];then
		dnf install -y expect &> /dev/null || { echo "expect安装失败，请检查网络";exit 1; }
	fi
	rm -rf .ssh
}

# 取ip地址
bring_host(){
	for ((i=$ONE;i<=$END;i++));do
		{ ping -c 1 -w 1 ${HOST}.$i &> /dev/null && echo "${HOST}.$i" >> ${ACTIVE_FILE}; }&
	done
	wait
}

# 配置ssh
ssh_config(){
	ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa &> /dev/null;wait
	for i in $(cat $ACTIVE_FILE);do
		{ expect <<EOF &> /dev/null
set timeout 20
spawn ssh-copy-id $i
expect {
	"yes/no" { send "yes\n";exp_continue }
	"password" { send "$PWD\n" }
}
expect eof
EOF
echo ${i}完成; }&
	done
	wait
}
prepare && bring_host && ssh_config
