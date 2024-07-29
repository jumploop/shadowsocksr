#!/usr/bin/env bash

GITHUB_RAW_URL="https://raw.githubusercontent.com/jumploop/shadowsocksr/master"
WORKDIR=/root/ssr
[ ! -d $WORKDIR ] && mkdir -p $WORKDIR

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————"

Set_config_port() {
    while true; do
        echo -e "请输入要设置的ShadowsocksR账号 端口"
        local default_port
        default_port=$(python -c 'import random;print(random.randint(1000, 65536))')
        read -r -e -p "(默认: $default_port):" ssr_port
        [[ -z "$ssr_port" ]] && ssr_port="$default_port"

        if echo $((ssr_port + 0)) &>/dev/null; then
            if [[ ${ssr_port} -ge 1 ]] && [[ ${ssr_port} -le 65535 ]]; then
                echo && echo ${Separator_1} && echo -e "	端口 : ${Green_font_prefix}${ssr_port}${Font_color_suffix}" && echo ${Separator_1} && echo
                break
            else
                echo -e "${Error} 请输入正确的数字(1-65535)"
            fi
        else
            echo -e "${Error} 请输入正确的数字(1-65535)"
        fi
    done
}

Set_config_password() {
    echo "请输入要设置的ShadowsocksR账号 密码"
    read -r -e -p "(默认: doub.io):" ssr_password
    [[ -z "${ssr_password}" ]] && ssr_password="doub.io"
    echo && echo ${Separator_1} && echo -e "	密码 : ${Green_font_prefix}${ssr_password}${Font_color_suffix}" && echo ${Separator_1} && echo
}

Set_config_method() {
    echo -e "请选择要设置的ShadowsocksR账号 加密方式

 ${Green_font_prefix} 1.${Font_color_suffix} none
 ${Tip} 如果使用 auth_chain_a 协议，请加密方式选择 none，混淆随意(建议 plain)

 ${Green_font_prefix} 2.${Font_color_suffix} rc4
 ${Green_font_prefix} 3.${Font_color_suffix} rc4-md5
 ${Green_font_prefix} 4.${Font_color_suffix} rc4-md5-6

 ${Green_font_prefix} 5.${Font_color_suffix} aes-128-ctr
 ${Green_font_prefix} 6.${Font_color_suffix} aes-192-ctr
 ${Green_font_prefix} 7.${Font_color_suffix} aes-256-ctr

 ${Green_font_prefix} 8.${Font_color_suffix} aes-128-cfb
 ${Green_font_prefix} 9.${Font_color_suffix} aes-192-cfb
 ${Green_font_prefix}10.${Font_color_suffix} aes-256-cfb

 ${Green_font_prefix}11.${Font_color_suffix} aes-128-cfb8
 ${Green_font_prefix}12.${Font_color_suffix} aes-192-cfb8
 ${Green_font_prefix}13.${Font_color_suffix} aes-256-cfb8

 ${Green_font_prefix}14.${Font_color_suffix} salsa20
 ${Green_font_prefix}15.${Font_color_suffix} chacha20
 ${Green_font_prefix}16.${Font_color_suffix} chacha20-ietf
 ${Tip} salsa20/chacha20-*系列加密方式，需要额外安装依赖 libsodium ，否则会无法启动ShadowsocksR !" && echo
    read -r -e -p "(默认: 5. aes-128-ctr):" ssr_method
    [[ -z "${ssr_method}" ]] && ssr_method="5"
    if [[ ${ssr_method} == "1" ]]; then
        ssr_method="none"
    elif [[ ${ssr_method} == "2" ]]; then
        ssr_method="rc4"
    elif [[ ${ssr_method} == "3" ]]; then
        ssr_method="rc4-md5"
    elif [[ ${ssr_method} == "4" ]]; then
        ssr_method="rc4-md5-6"
    elif [[ ${ssr_method} == "5" ]]; then
        ssr_method="aes-128-ctr"
    elif [[ ${ssr_method} == "6" ]]; then
        ssr_method="aes-192-ctr"
    elif [[ ${ssr_method} == "7" ]]; then
        ssr_method="aes-256-ctr"
    elif [[ ${ssr_method} == "8" ]]; then
        ssr_method="aes-128-cfb"
    elif [[ ${ssr_method} == "9" ]]; then
        ssr_method="aes-192-cfb"
    elif [[ ${ssr_method} == "10" ]]; then
        ssr_method="aes-256-cfb"
    elif [[ ${ssr_method} == "11" ]]; then
        ssr_method="aes-128-cfb8"
    elif [[ ${ssr_method} == "12" ]]; then
        ssr_method="aes-192-cfb8"
    elif [[ ${ssr_method} == "13" ]]; then
        ssr_method="aes-256-cfb8"
    elif [[ ${ssr_method} == "14" ]]; then
        ssr_method="salsa20"
    elif [[ ${ssr_method} == "15" ]]; then
        ssr_method="chacha20"
    elif [[ ${ssr_method} == "16" ]]; then
        ssr_method="chacha20-ietf"
    else
        ssr_method="aes-128-ctr"
    fi
    echo && echo ${Separator_1} && echo -e "	加密 : ${Green_font_prefix}${ssr_method}${Font_color_suffix}" && echo ${Separator_1} && echo
}

Set_config_protocol() {
    echo -e "请选择要设置的ShadowsocksR账号 协议插件

 ${Green_font_prefix}1.${Font_color_suffix} origin
 ${Green_font_prefix}2.${Font_color_suffix} auth_sha1_v4
 ${Green_font_prefix}3.${Font_color_suffix} auth_aes128_md5
 ${Green_font_prefix}4.${Font_color_suffix} auth_aes128_sha1
 ${Green_font_prefix}5.${Font_color_suffix} auth_chain_a
 ${Green_font_prefix}6.${Font_color_suffix} auth_chain_b
 ${Tip} 如果使用 auth_chain_a 协议，请加密方式选择 none，混淆随意(建议 plain)" && echo
    read -r -e -p "(默认: 2. auth_sha1_v4):" ssr_protocol
    [[ -z "${ssr_protocol}" ]] && ssr_protocol="2"
    if [[ ${ssr_protocol} == "1" ]]; then
        ssr_protocol="origin"
    elif [[ ${ssr_protocol} == "2" ]]; then
        ssr_protocol="auth_sha1_v4"
    elif [[ ${ssr_protocol} == "3" ]]; then
        ssr_protocol="auth_aes128_md5"
    elif [[ ${ssr_protocol} == "4" ]]; then
        ssr_protocol="auth_aes128_sha1"
    elif [[ ${ssr_protocol} == "5" ]]; then
        ssr_protocol="auth_chain_a"
    elif [[ ${ssr_protocol} == "6" ]]; then
        ssr_protocol="auth_chain_b"
    else
        ssr_protocol="auth_sha1_v4"
    fi
    echo && echo ${Separator_1} && echo -e "	协议 : ${Green_font_prefix}${ssr_protocol}${Font_color_suffix}" && echo ${Separator_1} && echo
    if [[ ${ssr_protocol} != "origin" ]]; then
        if [[ ${ssr_protocol} == "auth_sha1_v4" ]]; then
            read -r -e -p "是否设置 协议插件兼容原版(_compatible)？[Y/n]" ssr_protocol_yn
            [[ -z "${ssr_protocol_yn}" ]] && ssr_protocol_yn="y"
            [[ $ssr_protocol_yn == [Yy] ]] && ssr_protocol=${ssr_protocol}"_compatible"
            echo
        fi
    fi
}

Set_config_obfs() {
    echo -e "请选择要设置的ShadowsocksR账号 混淆插件

 ${Green_font_prefix}1.${Font_color_suffix} plain
 ${Green_font_prefix}2.${Font_color_suffix} http_simple
 ${Green_font_prefix}3.${Font_color_suffix} http_post
 ${Green_font_prefix}4.${Font_color_suffix} random_head
 ${Green_font_prefix}5.${Font_color_suffix} tls1.2_ticket_auth
 ${Tip} 如果使用 ShadowsocksR 加速游戏，请选择 混淆兼容原版或 plain 混淆，然后客户端选择 plain，否则会增加延迟 !
 另外, 如果你选择了 tls1.2_ticket_auth，那么客户端可以选择 tls1.2_ticket_fastauth，这样即能伪装又不会增加延迟 !
 如果你是在日本、美国等热门地区搭建，那么选择 plain 混淆可能被墙几率更低 !" && echo
    read -r -e -p "(默认: 1. plain):" ssr_obfs
    [[ -z "${ssr_obfs}" ]] && ssr_obfs="1"
    if [[ ${ssr_obfs} == "1" ]]; then
        ssr_obfs="plain"
    elif [[ ${ssr_obfs} == "2" ]]; then
        ssr_obfs="http_simple"
    elif [[ ${ssr_obfs} == "3" ]]; then
        ssr_obfs="http_post"
    elif [[ ${ssr_obfs} == "4" ]]; then
        ssr_obfs="random_head"
    elif [[ ${ssr_obfs} == "5" ]]; then
        ssr_obfs="tls1.2_ticket_auth"
    else
        ssr_obfs="plain"
    fi
    echo && echo ${Separator_1} && echo -e "	混淆 : ${Green_font_prefix}${ssr_obfs}${Font_color_suffix}" && echo ${Separator_1} && echo
    if [[ ${ssr_obfs} != "plain" ]]; then
        read -r -e -p "是否设置 混淆插件兼容原版(_compatible)？[Y/n]" ssr_obfs_yn
        [[ -z "${ssr_obfs_yn}" ]] && ssr_obfs_yn="y"
        [[ $ssr_obfs_yn == [Yy] ]] && ssr_obfs=${ssr_obfs}"_compatible"
        echo
    fi
}

Set_config_all() {
    Set_config_port
    Set_config_password
    Set_config_method
    Set_config_protocol
    Set_config_obfs
}

modify_config() {
    echo -e "请确认以下 ShadowsocksR账号信息是否正确:"
    sed -i "s/\${PORT}/${ssr_port}/g" docker-compose.yml
    sed -i "s/\${PASSWORD}/${ssr_password}/" docker-compose.yml
    sed -i "s/\${METHOD}/${ssr_method}/" docker-compose.yml
    sed -i "s/\${PROTOCOL}/${ssr_protocol}/" docker-compose.yml
    sed -i "s/\${OBFS}/${ssr_obfs}/" docker-compose.yml

}
# 获取 IP 并显示
get_ip() {
    ip="$(curl -s https://api.ipify.org | head -n 1)"
}

# 显示 配置信息
View_User() {
    get_ip
    clear && echo "===================================================" && echo
    echo -e " ShadowsocksR账号 配置信息：" && echo
    echo -e " I  P\t    : ${Green_font_prefix}${ip}${Font_color_suffix}"
    echo -e " 端口\t    : ${Green_font_prefix}${ssr_port}${Font_color_suffix}"
    echo -e " 密码\t    : ${Green_font_prefix}${ssr_password}${Font_color_suffix}"
    echo -e " 加密\t    : ${Green_font_prefix}${ssr_method}${Font_color_suffix}"
    echo -e " 协议\t    : ${Red_font_prefix}${ssr_protocol}${Font_color_suffix}"
    echo -e " 混淆\t    : ${Red_font_prefix}${ssr_obfs}${Font_color_suffix}"
    echo -e " 设备数限制 : ${Green_font_prefix}0(无限)${Font_color_suffix}"
    echo -e " 单线程限速 : ${Green_font_prefix}0 KB/S${Font_color_suffix}"
    echo -e " 端口总限速 : ${Green_font_prefix}0 KB/S${Font_color_suffix}"
    echo && echo "==================================================="
}
main() {
    echo -e "${Info} 开始设置 ShadowsocksR账号配置..."
    cd $WORKDIR || exit
    wget --no-check-certificate -O docker-compose.yml ${GITHUB_RAW_URL}/docker-compose.yml >/dev/null 2>&1
    wget --no-check-certificate -O Dockerfile ${GITHUB_RAW_URL}/Dockerfile >/dev/null 2>&1
    [ ! -e user-config.json ] && wget --no-check-certificate -O user-config.json ${GITHUB_RAW_URL}/config.json >/dev/null 2>&1
    Set_config_all
    modify_config
    View_User
    echo -e "> 启动SSR"

    (docker-compose up -d) >/dev/null 2>&1
}

main
