#!/bin/bash

# 返却文字列
RESULT_NOT_EXPIRE="Certificate will NOT expire within 30 days"
RESULT_EXPIRE="Certificate will expire within 30 days"
RESULT_UNABLE_TO_LOAD="Unable to load the certificate"

# Webhook 投稿先
CERTCHECK_URL="https://outlook.office.com/webhook/5128e755-da59-41a8-8d27-4fee03024f2a@457cc84b-70d4-4a9b-954b-e85b83bb4046/IncomingWebhook/ef504e98d5bc4463bc3b25012bb207c9/972a30b3-6a36-48b7-91b4-71f796dd7131"

TITLE="サーバー証明書の有効期限"
HOST="aaaa.com"
NOTAFTER="Nov 28 11:05:10 2020"
RESULT="30日以内に、有効期限が到来します"
EXPIRE_DATE=`date -d "${NOTAFTER}" "+%Y年%m月%d日_%H時%M分%S秒_GMT"`
echo $EXPIRE_DATE

# OK
curl -v -x gwproxy.daikin.co.jp:3128 -H 'Accept: application/json' -H 'Content-type: application/json' -X POST -d '{"title":'"${TITLE}"', "text":"- Host: '"${HOST}"'\n\n- NotAfter: '"${EXPIRE_DATE}"'\n\n- Result: '"${RESULT}"'"}' ${CERTCHECK_URL}

# -X POST -d '{"title":"サーバー証明書の有効期限", "text":"- Host: aaaa.com\n\n- NotAfter: 2020年11月28日_11:05:10_GMT\n\n- Result: 30日以内に、有効期限が到来します"}' ${CERTCHECK_URL}

