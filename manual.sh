#!/bin/bash

# $1 servername
# $2 port-number

# 証明書取得
openssl11 s_client -proxy gwproxy.daikin.co.jp:3128 -showcerts -connect $1:$2 -servername $1 < /dev/null > $1.txt 2>&1

# クライアント証明書を使って証明書取得
# openssl11 s_client -proxy gwproxy.daikin.co.jp:3128 -showcerts -connect $1:$2 -servername $1 -cert P000000000000046.crt -key P000000000000046.key< /dev/null > $1.txt 2>&1
 
# 有効期限取得
openssl11 x509 -in $1.txt -enddate
