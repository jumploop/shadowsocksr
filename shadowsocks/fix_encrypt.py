#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import os
import subprocess
import configparser
import shutil
import encrypt_test

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
        config_dir = output.split(':"')[1].split('"')[0]
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

    if not version or not config_path:
        logging.error("无法获取 OpenSSL 版本或配置信息")
        return False

    if version[0] < 3:
        logging.info("OpenSSL 版本 %d.%d 无需启用遗留算法", version[0], version[1])
        return True

    config = configparser.ConfigParser()
    try:
        config.read(config_path)

        # 配置相关段
        for section, settings in {
            'openssl_init': {'providers': 'provider_sect'},
            'provider_sect': {'default': 'default_sect', 'legacy': 'legacy_sect'},
            'default_sect': {'activate': '1'},
            'legacy_sect': {'activate': '1', 'providers': 'legacy'},
        }.items():
            if section not in config:
                config[section] = {}
            config[section].update(settings)

        # 备份和写入配置
        backup_path = config_path + ".bak"
        shutil.copy2(config_path, backup_path)
        with open(config_path, 'w') as f:
            config.write(f)

        logging.info("已启用遗留算法")
        return True

    except Exception as e:
        logging.error("修改 OpenSSL 配置文件失败: %s", e)
        if os.path.exists(backup_path):
            shutil.copy2(backup_path, config_path)
            logging.info("已恢复备份")
        return False


def main():
    """主函数。"""
    try:
        encrypt_test.main()
    except Exception:
        logging.error("加密测试失败")
        if enable_legacy_algorithms():
            logging.info("已启用遗留算法支持，请重试")
            encrypt_test.main()
        else:
            logging.error("启用遗留算法支持失败")


if __name__ == '__main__':
    main()
