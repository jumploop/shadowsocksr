#!/usr/bin/env python
#
# Copyright 2015 clowwindy
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

from __future__ import absolute_import, division, print_function, \
    with_statement

from ctypes import c_char_p, c_int, c_long, byref, \
    create_string_buffer, c_void_p

from shadowsocks import common
from shadowsocks.crypto import util

__all__ = ['ciphers']

libcrypto = None
loaded = False

buf_size = 2048

ctx_cleanup = None

def load_openssl():
    global loaded, libcrypto, buf, ctx_cleanup

    libcrypto = util.find_library(('crypto', 'eay32'),
                                  'EVP_get_cipherbyname',
                                  'libcrypto')
    if libcrypto is None:
        raise Exception('libcrypto(OpenSSL) not found')

    libcrypto.EVP_get_cipherbyname.restype = c_void_p
    libcrypto.EVP_CIPHER_CTX_new.restype = c_void_p

    libcrypto.EVP_CipherInit_ex.argtypes = (c_void_p, c_void_p, c_char_p,
                                            c_char_p, c_char_p, c_int)

    libcrypto.EVP_CipherUpdate.argtypes = (c_void_p, c_void_p, c_void_p,
                                           c_char_p, c_int)

    if hasattr(libcrypto, "EVP_CIPHER_CTX_cleanup"):
        libcrypto.EVP_CIPHER_CTX_cleanup.argtypes = (c_void_p,)
        ctx_cleanup = libcrypto.EVP_CIPHER_CTX_cleanup
    else:
        libcrypto.EVP_CIPHER_CTX_reset.argtypes = (c_void_p,)
        ctx_cleanup = libcrypto.EVP_CIPHER_CTX_reset
    libcrypto.EVP_CIPHER_CTX_free.argtypes = (c_void_p,)

    libcrypto.RAND_bytes.restype = c_int
    libcrypto.RAND_bytes.argtypes = (c_void_p, c_int)

    if hasattr(libcrypto, 'OpenSSL_add_all_ciphers'):
        libcrypto.OpenSSL_add_all_ciphers()

    buf = create_string_buffer(buf_size)
    loaded = True


def load_cipher(cipher_name):
    func_name = 'EVP_' + cipher_name.replace('-', '_')
    cipher = getattr(libcrypto, func_name, None)
    if cipher:
        cipher.restype = c_void_p
        return cipher()
    return None


def rand_bytes(length):
    if not loaded:
        load_openssl()
    buf = create_string_buffer(length)
    r = libcrypto.RAND_bytes(buf, length)
    if r <= 0:
        raise Exception('RAND_bytes return error')
    return buf.raw


class OpenSSLCrypto(object):
    def __init__(self, cipher_name, key, iv, op):
        self._ctx = None
        if not loaded:
            load_openssl()
        cipher = libcrypto.EVP_get_cipherbyname(common.to_bytes(cipher_name))
        if not cipher:
            cipher = load_cipher(cipher_name)
        if not cipher:
            raise Exception('cipher %s not found in libcrypto' % cipher_name)
        key_ptr = c_char_p(key)
        iv_ptr = c_char_p(iv)
        self._ctx = libcrypto.EVP_CIPHER_CTX_new()
        if not self._ctx:
            raise Exception('can not create cipher context')
        r = libcrypto.EVP_CipherInit_ex(self._ctx, cipher, None,
                                        key_ptr, iv_ptr, c_int(op))
        if not r:
            self.clean()
            raise Exception('can not initialize cipher context')

    def update(self, data):
        global buf_size, buf
        cipher_out_len = c_long(0)
        l = len(data)
        if buf_size < l:
            buf_size = l * 2
            buf = create_string_buffer(buf_size)
        libcrypto.EVP_CipherUpdate(self._ctx, byref(buf),
                                   byref(cipher_out_len), c_char_p(data), l)
        # buf is copied to a str object when we access buf.raw
        return buf.raw[:cipher_out_len.value]

    def __del__(self):
        self.clean()

    def clean(self):
        if self._ctx:
            ctx_cleanup(self._ctx)
            libcrypto.EVP_CIPHER_CTX_free(self._ctx)
            self._ctx = None


ciphers = {
    # CBC mode need a special use way that different from other.
    # CBC mode encrypt message with 16n length, and need 16n+1 length space to decrypt it , otherwise don't decrypt it
    'aes-128-cbc': (16, 16, OpenSSLCrypto),
    'aes-192-cbc': (24, 16, OpenSSLCrypto),
    'aes-256-cbc': (32, 16, OpenSSLCrypto),
    'aes-128-gcm': (16, 16, OpenSSLCrypto),
    'aes-192-gcm': (24, 16, OpenSSLCrypto),
    'aes-256-gcm': (32, 16, OpenSSLCrypto),
    'aes-128-cfb': (16, 16, OpenSSLCrypto),
    'aes-192-cfb': (24, 16, OpenSSLCrypto),
    'aes-256-cfb': (32, 16, OpenSSLCrypto),
    'aes-128-ofb': (16, 16, OpenSSLCrypto),
    'aes-192-ofb': (24, 16, OpenSSLCrypto),
    'aes-256-ofb': (32, 16, OpenSSLCrypto),
    'aes-128-ctr': (16, 16, OpenSSLCrypto),
    'aes-192-ctr': (24, 16, OpenSSLCrypto),
    'aes-256-ctr': (32, 16, OpenSSLCrypto),
    'aes-128-cfb8': (16, 16, OpenSSLCrypto),
    'aes-192-cfb8': (24, 16, OpenSSLCrypto),
    'aes-256-cfb8': (32, 16, OpenSSLCrypto),
    'aes-128-cfb1': (16, 16, OpenSSLCrypto),
    'aes-192-cfb1': (24, 16, OpenSSLCrypto),
    'aes-256-cfb1': (32, 16, OpenSSLCrypto),
    'bf-cfb': (16, 8, OpenSSLCrypto),
    'camellia-128-cfb': (16, 16, OpenSSLCrypto),
    'camellia-192-cfb': (24, 16, OpenSSLCrypto),
    'camellia-256-cfb': (32, 16, OpenSSLCrypto),
    'cast5-cfb': (16, 8, OpenSSLCrypto),
    'des-cfb': (8, 8, OpenSSLCrypto),
    'idea-cfb': (16, 8, OpenSSLCrypto),
    'rc2-cfb': (16, 8, OpenSSLCrypto),
    'rc4': (16, 0, OpenSSLCrypto),
    'seed-cfb': (16, 16, OpenSSLCrypto),
}


def run_method(method):
    cipher = OpenSSLCrypto(method, b'k' * 32, b'i' * 16, 1)
    decipher = OpenSSLCrypto(method, b'k' * 32, b'i' * 16, 0)

    util.run_cipher(cipher, decipher)


def test_aes_128_cfb():
    run_method('aes-128-cfb')


def test_aes_256_cfb():
    run_method('aes-256-cfb')


def test_aes_128_cfb8():
    run_method('aes-128-cfb8')


def test_aes_256_ofb():
    run_method('aes-256-ofb')


def test_aes_256_ctr():
    run_method('aes-256-ctr')


def test_bf_cfb():
    run_method('bf-cfb')


def test_rc4():
    run_method('rc4')


def test_all():
    for k, v in ciphers.items():
        print(k)
        try:
            run_method(k)
        except AssertionError as e:
            eprint("AssertionError===========" + k)
            eprint(e)


def eprint(*args, **kwargs):
    import sys
    print(*args, file=sys.stderr, **kwargs)


if __name__ == '__main__':
    test_aes_128_cfb()
