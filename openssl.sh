
# Windows10
openssl s_client -proxy gwproxy.daikin.co.jp:3128 -connect www.daikin.co.jp:443 -servername www.daikin.co.jp < nul > daikin-ca-win.txt 2>&1

# ZCC 後は↓可
openssl s_client -connect www.daikin.co.jp:443 -servername www.daikin.co.jp < nul > daikin-ca-win.txt 2>&1

# 期限チェック
openssl x509 -in a2x70trv67in46.iot.ap-northeast-1.amazonaws.com-ca.txt -checkend 2592000 -enddate
notAfter=Aug  8 23:59:59 2021 GMT
Certificate will not expire

# CentOS7
openssl11 s_client -proxy gwproxy.daikin.co.jp:3128 -connect www.daikin.co.jp:443 -servername www.daikin.co.jp < /dev/null > daikin-ca-centos7.txt 2>&1

openssl11 s_client -proxy gwproxy.daikin.co.jp:3128 -connect a2x70trv67in46.iot.ap-northeast-1.amazonaws.com:443 -servername a2x70trv67in46.iot.ap-northeast-1.amazonaws.com < /dev/null > a2x70trv67in46.iot.ap-northeast-1.amazonaws.com-ca.txt

# 期限チェック
openssl11 x509 -in a2x70trv67in46.iot.ap-northeast-1.amazonaws.com-ca.txt -checkend 2592000 -enddate
notAfter=Aug  8 23:59:59 2021 GMT
Certificate will not expire