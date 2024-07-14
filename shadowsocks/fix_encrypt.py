#!/usr/bin/env python
# -*- coding: utf-8
from __future__ import absolute_import, division, print_function, with_statement

import fileinput
from contextlib import closing

from shadowsocks import encrypt_test


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
