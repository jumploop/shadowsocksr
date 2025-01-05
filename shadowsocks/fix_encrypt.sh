#!/bin/bash

# 获取 OpenSSL 配置文件的目录
OPENSSL_DIR=$(openssl version -d | cut -d'"' -f2)
CONFIG_FILE="$OPENSSL_DIR/openssl.cnf"

# 检查配置文件是否存在
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "错误: 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 备份原始配置文件
BACKUP_FILE="$CONFIG_FILE.bak"
if cp "$CONFIG_FILE" "$BACKUP_FILE"; then
    echo "已备份配置文件到: $BACKUP_FILE"
else
    echo "错误: 无法备份配置文件."
    exit 1
fi

# 检查是否已添加 Legacy Providers
if grep -qE "^\[legacy_sect\]" "$CONFIG_FILE" && grep -qE "^\s*activate\s*=\s*1" "$CONFIG_FILE"; then
    echo "Legacy Providers 已经启用，无需再次添加."
    exit 0
fi

# 添加 Legacy Providers 配置
{
    echo -e "\n# List of providers to load"
    echo "[provider_sect]"
    echo "default = default_sect"
    echo "legacy = legacy_sect"
    echo ""
    echo "[default_sect]"
    echo "activate = 1"
    echo ""
    echo "[legacy_sect]"
    echo "activate = 1"
} >> "$CONFIG_FILE"

# 确保配置文件末尾没有多余的空行
sed -i '/^$/d' "$CONFIG_FILE"

echo "已更新配置文件以启用 Legacy Providers."

# 验证更改
if openssl list -providers | grep -q "legacy"; then
    echo "Legacy Providers 已成功启用."
else
    echo "错误: Legacy Providers 未能启用."
fi