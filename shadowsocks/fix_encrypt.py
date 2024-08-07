#!/usr/bin/env python
# -*- coding: utf-8
from __future__ import absolute_import, division, print_function, with_statement

import fileinput
import logging
import os
import shlex
import subprocess
from contextlib import closing
from threading import Timer

import encrypt_test

logging.basicConfig(level=logging.INFO)


# https://blog.vinsonws.cn/2023/05/25/openssl-openssl3-%E5%A6%82%E4%BD%95%E5%BC%80%E5%90%AF-rc4-md5-%E6%94%AF%E6%8C%81/
# 如果发现改完还是不行的话，尝试使用openssl version -d来确认修改的配置文件在该目录下
#
# Ref:
# https://www.practicalnetworking.net/practical-tls/openssl-3-and-legacy-providers/


def exe_command(cmdstr, timeout=1800, shell=False):
    if shell:
        command = cmdstr
    else:
        command = shlex.split(cmdstr)
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=shell)
    timer = Timer(timeout, process.kill)
    try:
        timer.start()
        stdout, stderr = process.communicate()
        retcode = process.poll()
        result = (stdout + stderr).strip()
        shellresult = result if isinstance(result, str) else str(result, encoding='utf-8')
        logging.info('execute shell [%s], shell result is\n%s', cmdstr, shellresult)
        return retcode, shellresult
    finally:
        timer.cancel()


def enable_rc4_legacy():
    openssl_conf = "/etc/ssl/openssl.cnf"
    try:
        code, result = exe_command('openssl version -d')
        if result.startswith('OPENSSLDIR'):
            openssl_conf = os.path.join(result.split()[-1].strip('"'), 'openssl.cnf')
    except Exception as e:
        logging.error('execute shell failed: %s', e)
    logging.info('openssl config file %s', openssl_conf)
    std = ['[provider_sect]', 'legacy = legacy_sect', '[legacy_sect]', 'activate = 1']
    with open(openssl_conf, 'r') as f:
        for line in f.read().splitlines():
            if line in std:
                std.remove(line)
    if std:
        modify_config(openssl_conf)


def modify_config(openssl_conf):
    with closing(fileinput.input(openssl_conf, inplace=True)) as file:
        for line in file:
            line = line.rstrip()
            if line.startswith('[provider_sect]'):
                print(line)
                print('legacy = legacy_sect')
            elif line.startswith('[default_sect]'):
                print(line)
                print('activate = 1')
                print('[legacy_sect]')
                print('activate = 1')
            else:
                print(line)


def main():
    try:
        encrypt_test.main()
    except Exception as e:
        enable_rc4_legacy()


if __name__ == '__main__':
    main()
