#!/usr/bin/env python
# -*- coding: utf-8
from __future__ import absolute_import, division, print_function, with_statement

import fileinput
from contextlib import closing

import encrypt_test

# https://blog.vinsonws.cn/2023/05/25/openssl-openssl3-%E5%A6%82%E4%BD%95%E5%BC%80%E5%90%AF-rc4-md5-%E6%94%AF%E6%8C%81/
def enable_rc4_legacy():
    openssl_conf = "/etc/ssl/openssl.cnf"
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
