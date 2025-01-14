#!/usr/bin/env bash
################################
filebrowser_main() {
    case "$1" in
    r | -r) filebrowser_restart ;;
    *)
        install_filebrowser
        ;;
    esac
}
##################
install_filebrowser() {
    if [ ! $(command -v filebrowser) ]; then
        cd /tmp
        case "${ARCH_TYPE}" in
        "amd64" | "arm64")
            rm -rf .FileBrowserTEMPFOLDER
            git clone -b linux_${ARCH_TYPE} --depth=1 https://gitee.com/mo2/filebrowser.git ./.FileBrowserTEMPFOLDER
            cd /usr/local/bin
            tar -Jxvf /tmp/.FileBrowserTEMPFOLDER/filebrowser.tar.xz filebrowser
            chmod +x filebrowser
            rm -rf /tmp/.FileBrowserTEMPFOLDER
            ;;
        *)
            #https://github.com/filebrowser/filebrowser/releases
            #curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
            case "${ARCH_TYPE}" in
            "armhf") aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o .filebrowser.tar.gz 'https://github.com/filebrowser/filebrowser/releases/download/v2.1.0/linux-armv7-filebrowser.tar.gz' ;;
            "i386") aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o .filebrowser.tar.gz 'https://github.com/filebrowser/filebrowser/releases/download/v2.1.0/linux-386-filebrowser.tar.gz' ;;
            esac
            cd /usr/local/bin
            tar -zxvf /tmp/.filebrowser.tar.gz filebrowser
            chmod +x filebrowser
            rm -rf /tmp/.filebrowser.tar.gz
            ;;
        esac
    fi
    pgrep filebrowser &>/dev/null
    if [ "$?" = "0" ]; then
        FILEBROWSER_STATUS='检测到filebrowser进程正在运行'
        FILEBROWSER_PROCESS='Restart重启'
    else
        FILEBROWSER_STATUS='检测到filebrowser进程未运行'
        FILEBROWSER_PROCESS='Start启动'
    fi

    if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${FILEBROWSER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${FILEBROWSER_STATUS}" 9 50); then
        if [ ! -e "/etc/filebrowser.db" ]; then
            printf "%s\n" "检测到数据库文件不存在，2s后将为您自动配置服务。"
            sleep 2s
            filebrowser_onekey
        fi
        filebrowser_restart
    else
        configure_filebrowser
    fi
}
############
configure_filebrowser() {
    #先进入etc目录，防止database加载失败
    cd /etc
    TMOE_OPTION=$(
        whiptail --title "CONFIGURE FILEBROWSER" --menu "您想要修改哪项配置？修改配置前将自动停止服务。" 0 50 0 \
            "1" "One-key conf 初始化一键配置" \
            "2" "add admin 新建管理员" \
            "3" "port 修改端口" \
            "4" "view logs 查看日志" \
            "5" "language语言环境" \
            "6" "listen addr/ip 监听ip" \
            "7" "进程管理说明" \
            "8" "stop 停止" \
            "9" "reset 重置所有配置信息" \
            "10" "remove 卸载/移除" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    ##############################
    if [ "${TMOE_OPTION}" == '0' ]; then
        #tmoe_linux_tool_menu
        personal_netdisk
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '1' ]; then
        pkill filebrowser
        service filebrowser stop 2>/dev/null || systemctl stop filebrowser
        filebrowser_onekey
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '2' ]; then
        pkill filebrowser
        service filebrowser stop 2>/dev/null || systemctl stop filebrowser
        filebrowser_add_admin
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '3' ]; then
        pkill filebrowser
        service filebrowser stop 2>/dev/null || systemctl stop filebrowser
        filebrowser_port
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '4' ]; then
        filebrowser_logs
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '5' ]; then
        pkill filebrowser
        service filebrowser stop 2>/dev/null || systemctl stop filebrowser
        filebrowser_language
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '6' ]; then
        pkill filebrowser
        service filebrowser stop 2>/dev/null || systemctl stop filebrowser
        filebrowser_listen_ip
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '7' ]; then
        filebrowser_systemd
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '8' ]; then
        printf "%s\n" "正在停止服务进程..."
        printf "%s\n" "Stopping..."
        pkill filebrowser
        service filebrowser stop 2>/dev/null || systemctl stop filebrowser
        service filebrowser status 2>/dev/null || systemctl status filebrowser
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '9' ]; then
        pkill filebrowser
        service filebrowser stop 2>/dev/null || systemctl stop filebrowser
        filebrowser_reset
    fi
    ##############################
    if [ "${TMOE_OPTION}" == '10' ]; then
        RETURN_TO_WHERE='configure_filebrowser'
        do_you_want_to_continue
        pkill filebrowser
        systemctl disable filebrowser
        service filebrowser stop 2>/dev/null || systemctl stop filebrowser
        rm -fv /usr/local/bin/filebrowser
        rm -fv /etc/systemd/system/filebrowser.service
        rm -fv /etc/filebrowser.db
    fi
    ########################################
    if [ -z "${TMOE_OPTION}" ]; then
        personal_netdisk
    fi
    ###########
    press_enter_to_return
    configure_filebrowser
}
##############
filebrowser_onekey() {
    cd /etc
    #初始化数据库文件
    filebrowser -d filebrowser.db config init
    #监听0.0.0.0
    filebrowser config set --address 0.0.0.0
    #设定根目录为当前主目录
    filebrowser config set --root ${HOME}
    filebrowser config set --port 38080
    #设置语言环境为中文简体
    filebrowser config set --locale zh-cn
    #修改日志文件路径
    #filebrowser config set --log /var/log/filebrowser.log
    TARGET_USERNAME=$(whiptail --inputbox "请输入自定义用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        printf "%s\n" "用户名无效，请返回重试。"
        press_enter_to_return
        filebrowser_onekey
    fi
    TARGET_USERPASSWD=$(whiptail --inputbox "请设定管理员密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        printf "%s\n" "密码包含无效字符，请返回重试。"
        press_enter_to_return
        filebrowser_onekey
    fi
    filebrowser users add ${TARGET_USERNAME} ${TARGET_USERPASSWD} --perm.admin
    #filebrowser users update ${TARGET_USERNAME} ${TARGET_USERPASSWD}

    cat >/etc/systemd/system/filebrowser.service <<-'EndOFsystemd'
		[Unit]
		Description=FileBrowser
		After=network.target
		Wants=network.target

		[Service]
		Type=simple
		PIDFile=/var/run/filebrowser.pid
		ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser.db
		Restart=on-failure

		[Install]
		WantedBy=multi-user.target
	EndOFsystemd
    chmod +x /etc/systemd/system/filebrowser.service
    systemctl daemon-reload 2>/dev/null
    #systemctl start filebrowser
    #service filebrowser start
    if (whiptail --title "systemctl enable filebrowser？" --yes-button 'Yes' --no-button 'No！' --yesno "是否需要将此服务设置为开机自启？" 9 50); then
        systemctl enable filebrowser
    fi
    filebrowser_restart
    ########################################
    press_enter_to_return
    configure_filebrowser
    #此处的返回步骤并非多余
}
############
filebrowser_restart() {
    FILEBROWSER_PORT=$(sed -n p /etc/filebrowser.db | grep -a port | sed 's@,@\n@g' | grep -a port | head -n 1 | cut -d ':' -f 2 | cut -d '"' -f 2)
    service filebrowser restart 2>/dev/null || systemctl restart filebrowser
    if [ "$?" != "0" ]; then
        pkill filebrowser
        nohup /usr/local/bin/filebrowser -d /etc/filebrowser.db 2>&1 >/var/log/filebrowser.log &
        sed -n p /var/log/filebrowser.log | tail -n 20
    fi
    service filebrowser status 2>/dev/null || systemctl status filebrowser
    if [ "$?" = "0" ]; then
        printf "%s\n" "您可以输${YELLOW}service filebrowser stop${RESET}来停止进程"
    else
        printf "%s\n" "您可以输${YELLOW}pkill filebrowser${RESET}来停止进程"
    fi
    printf "%s\n" "正在为您启动filebrowser服务，本机默认访问地址为localhost:${FILEBROWSER_PORT}"
    echo The LAN address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${FILEBROWSER_PORT}
    echo The WAN address 外网地址 $(curl -sL ip.cip.cc | head -n 1):${FILEBROWSER_PORT}
    printf "%s\n" "${YELLOW}请使用浏览器打开上述地址${RESET}"
    printf "%s\n" "Please use your browser to open the access address"
}
#############
filebrowser_add_admin() {
    pkill filebrowser
    service filebrowser stop 2>/dev/null || systemctl stop filebrowser
    printf "%s\n" "Stopping filebrowser..."
    printf "%s\n" "正在停止filebrowser进程..."
    printf "%s\n" "正在检测您当前已创建的用户..."
    filebrowser -d /etc/filebrowser.db users ls
    printf '%s\n' 'Press Enter to continue.'
    printf "%s\n" "${YELLOW}按回车键继续。${RESET}"
    read
    TARGET_USERNAME=$(whiptail --inputbox "请输入自定义用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        printf "%s\n" "用户名无效，操作取消"
        press_enter_to_return
        configure_filebrowser
    fi
    TARGET_USERPASSWD=$(whiptail --inputbox "请设定管理员密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        printf "%s\n" "密码包含无效字符，请返回重试。"
        press_enter_to_return
        filebrowser_add_admin
    fi
    cd /etc
    filebrowser users add ${TARGET_USERNAME} ${TARGET_USERPASSWD} --perm.admin
    #filebrowser users update ${TARGET_USERNAME} ${TARGET_USERPASSWD} --perm.admin
}
#################
filebrowser_port() {
    FILEBROWSER_PORT=$(sed -n p /etc/filebrowser.db | grep -a port | sed 's@,@\n@g' | grep -a port | head -n 1 | cut -d ':' -f 2 | cut -d '"' -f 2)
    TARGET_PORT=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,检测到您当前的端口为${FILEBROWSER_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        printf "%s\n" "检测到您取消了操作，请返回重试。"
        press_enter_to_return
        configure_filebrowser
    fi
    filebrowser config set --port ${TARGET_PORT}
}
############
filebrowser_logs() {
    if [ ! -f "/var/log/filebrowser.log" ]; then
        printf "%s\n" "日志文件不存在，您可能没有启用记录日志的功能"
        printf "%s\n" "${YELLOW}按回车键启用。${RESET}"
        read
        filebrowser -d /etc/filebrowser.db config set --log /var/log/filebrowser.log
    fi
    ls -lh /var/log/filebrowser.log
    printf "%s\n" "按Ctrl+C退出日志追踪，press Ctrl+C to exit."
    tail -Fvn 35 /var/log/filebrowser.log
    #if [ $(command -v less) ]; then
    # sed -n p /var/log/filebrowser.log | less -meQ
    #else
    # sed -n p /var/log/filebrowser.log
    #fi

}
#################
filebrowser_language() {
    TARGET_LANG=$(whiptail --inputbox "Please enter the language format, for example en,zh-cn" 12 50 --title "LANGUAGE" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        printf "%s\n" "检测到您取消了操作，请返回重试。"
        press_enter_to_return
        configure_filebrowser
    fi
    filebrowser config set --port ${TARGET_LANG}
}
###############
filebrowser_listen_ip() {
    TARGET_IP=$(whiptail --inputbox "Please enter the listen address, for example 0.0.0.0\n默认情况下无需修改。" 12 50 --title "listen" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        printf "%s\n" "检测到您取消了操作，请返回重试。"
        press_enter_to_return
        configure_filebrowser
    fi
    filebrowser config set --address ${TARGET_IP}
}
##################
filebrowser_systemd() {
    case "${TMOE_PROOT}" in
    true | no)
        printf "%s\n" "检测到您当前处于${BLUE}proot容器${RESET}环境下，无法使用systemctl命令"
        ;;
    false) printf "%s\n" "检测到您当前处于chroot容器环境下，无法使用systemctl命令" ;;
    esac
    cat <<-'EOF'
		systemd管理
			输systemctl start filebrowser启动
			输systemctl stop filebrowser停止
			输systemctl status filebrowser查看进程状态
			输systemctl enable filebrowser开机自启
			输systemctl disable filebrowser禁用开机自启

			service命令
			输service filebrowser start启动
			输service filebrowser stop停止
			输service filebrowser status查看进程状态
		        
		    其它命令(适用于service和systemctl都无法使用的情况)
			输debian-i file启动
			pkill filebrowser停止
	EOF
}
###############
filebrowser_reset() {
    printf "%s\n" "${YELLOW}WARNING！继续执行此操作将丢失所有配置信息！${RESET}"
    RETURN_TO_WHERE='configure_filebrowser'
    do_you_want_to_continue
    rm -vf filebrowser.db
    filebrowser -d filebrowser.db config init
}
##############
filebrowser_main
