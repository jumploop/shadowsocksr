#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import os
import re
import subprocess
import encrypt_test
from fileinput import input

# 配置日志记录
logging.basicConfig(
    level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s'
)


def execute_command(command):
    """执行 shell 命令并返回结果。"""
    try:
        process = subprocess.Popen(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True
        )
        stdout, stderr = process.communicate()
        output = (stdout + stderr).decode('utf-8').strip()
        logging.info(
            "执行命令: '%s', 返回码: %d, 输出: \n%s",
            command,
            process.returncode,
            output,
        )
        return process.returncode, output
    except Exception as e:
        logging.error("执行命令 '%s' 失败: %s", command, e)
        return -1, str(e)


def get_openssl_info():
    """获取 OpenSSL 版本和配置信息。"""
    version = None
    config_path = None

    # 获取版本
    returncode, output = execute_command('openssl version')
    if returncode == 0:
        version_string = output.split()[1]
        version = tuple(map(int, version_string.split('.')[:2]))

    # 获取配置路径
    returncode, output = execute_command('openssl version -d')
    if returncode == 0 and 'OPENSSLDIR' in output:
        config_dir = output.split(':')[1].strip().split('"')[1]
        for path in [
            os.path.join(config_dir, 'openssl.cnf'),
            os.path.join(config_dir, 'openssl.conf'),
            "/etc/ssl/openssl.cnf",
            "/usr/local/ssl/openssl.cnf",
        ]:
            if os.path.exists(path):
                config_path = path
                break

    return version, config_path


def enable_legacy_algorithms():
    """启用 OpenSSL 遗留算法。"""
    version, config_path = get_openssl_info()
    logging.info('version: %s, config_path: %s', version, config_path)
    if not version or not config_path:
        logging.error("无法获取 OpenSSL 版本或配置信息")
        return False

    if version[0] < 3:
        logging.info("OpenSSL 版本 %d.%d 无需启用遗留算法", version[0], version[1])
        return True

    # 备份和写入配置
    for line in input(config_path, inplace=True, backup=".bak"):
        line = line.strip()
        if re.match(r'#*\s*providers = provider_sect', line):
            print('providers = provider_sect')
        elif re.match(r'#*\s*\[provider_sect\]', line):
            print('[provider_sect]')
        elif re.match(r'#*\s*default = default_sect', line):
            print('default = default_sect')
            print('legacy = legacy_sect')
        elif re.match(r'#*\s*\[default_sect\]', line):
            print('[default_sect]')
        elif re.match(r'#*\s*activate = 1', line):
            print('activate = 1')
            print('[legacy_sect]')
            print('activate = 1')
        else:
            print(line)
    logging.info("已启用遗留算法")
    return True


def main():
    """主函数。"""
    try:
        encrypt_test.main()
    except Exception:
        logging.error("加密测试失败")
        enable_legacy_algorithms()
        _, providers_output = execute_command('openssl list -providers')
        if 'legacy' in providers_output and 'default' in providers_output:
            logging.info("已启用遗留算法支持，请重试")
        else:
            logging.error("启用遗留算法支持失败")


if __name__ == '__main__':
    main()
