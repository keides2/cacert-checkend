#!/bin/bash

# サーバ一覧ファイルの在りか
# URLList="/home/vuls/CAcert/list-hosts.csv"
URLList="/mnt/z/空調生産本部ITソリューション開発Ｇ/LVL2/開発g/脆弱性情報/cacert/list-hosts.csv"

# Zドライブのログ保存先
Z_LOG_DIR="/mnt/z/空調生産本部ITソリューション開発Ｇ/LVL2/開発g/脆弱性情報/cacert/result/"

# Home: フルパスで
HOME="/home/vuls/CAcert/"

# 認証局の証明書ファイルの在りかを指定
OsslClientOpts="-CAfile /etc/ssl/certs/ca-bundle.crt"

# 2592000秒＝30日 後に、有効期間が終了しているかどうか判定するためのopenssl11コマンドオプション
OsslX509Opts="-checkend 2592000"

# Teams Webhook 通知用文字列
TITLE="サーバー証明書の有効期限チェック"
# HOST="aaaa.com"
# NOTAFTER="Nov 28 11:05:10 2020"
# EXPIRE_DATE=`date -d "${NOTAFTER}" "+%Y年%m月%d日-%H時%M分%S秒-JST"`
# echo $EXPIRE_DATE
RESULT=""
RESULT_NOT_EXPIRE="30日以内に、有効期限は到来しません"
RESULT_EXPIRE="**30日以内に、有効期限が到来します**"    # **は、MarkDownの強調文字指定
RESULT_UNABLE_TO_LOAD="証明書を取得できませんでした"

# Webhook 投稿先 チャネル「サーバー証明書」＞コネクタ「CAcertCheckend」
CERTCHECK_URL="https://outlook.office.com/webhook/5128e755-da59-41a8-8d27-4fee03024f2a@457cc84b-70d4-4a9b-954b-e85b83bb4046/IncomingWebhook/dd0b0d499d46445cb11357a5544db9cb/972a30b3-6a36-48b7-91b4-71f796dd7131"

# 全証明書が更新間近でなかった場合の通知判定用積算値
OPENSSL_RET_VALUE=0

# 全証明書が更新間近でなかった場合のメッセージ
MESS_NO_EXPIRE="※30日以内に、有効期限が到来する証明書はありませんでした"

# ---------- SSLサーバ証明書の有効期間を判定 ----------
MyOpenSSL() {
    # $1 HOST
    # $2 PORT
    # $3 SERVICE
    echo HOST:$1 PORT:$2 SERVICE:$3

    if [ $3 == "startssl" ]; then
        openssl11 s_client -proxy gwproxy.daikin.co.jp:3128 -connect $1:$2 ${OsslClientOpts} -name $1 -starttls smtp < /dev/null 1>> ${HOME}cacert-$1.txt 2>&1
    else
        # プロキシー Trustwave の証明書が出てくる。が、証明書の期限は接続先のもの
        # openssl11 s_client -proxy gwproxy.daikin.co.jp:3128 -connect ${HOST}:${PORT} ${OsslClientOpts} -servername ${HOST}  <nul | openssl11 x509 ${OsslX509Opts} -enddate
        openssl11 s_client -proxy gwproxy.daikin.co.jp:3128 -connect $1:$2 ${OsslClientOpts} -servername $1 < /dev/null 1>> ${HOME}cacert-$1.txt 2>&1
    fi
    openssl11 x509 -in ${HOME}cacert-$1.txt ${OsslX509Opts} -enddate 1>> ${HOME}cacert-$1.txt 2>&1

    # openssl11 実行後の戻り値: 戻り値が0より大きい場合、期限切れが間近だと見なして通知する（期限内なら0）
    if [ $? -gt 0 ]; then 
        # ただし証明書か取得できない場合がある
        grep -i "DONE" ${HOME}cacert-$1.txt
        if [ $? -gt 0 ]; then
            # 証明書を取得できなかった
            # echo ${RESULT_UNABLE_TO_LOAD} >> ${HOME}cacert-$1.txt
            Notification_Unable_To_Load
        else
            # 証明書を取得できた
            # echo ${RESULT_EXPIRE} >> ${HOME}cacert-$1.txt
            Notification_Expire
        fi
    else
        # 期限切れではない
        # echo ${RESULT_NOT_EXPIRE} >> ${HOME}cacert-$1.txt
        Notification_Not_Expire
    fi

}

# ---------- 通知の送信 ----------
Notification_Expire() {
    # 証明書を取得できたが、期限切れが間近
    echo ${RESULT_EXPIRE}

	# 有効期限
    NOTAFTER=`grep notAfter ${HOME}cacert-${HOST}.txt`
	echo ${NOTAFTER}    # notAfter=Aug 8 23:59:59 2021 GMT
    # "notAfter=" を削除して日本語でJST表示
	EXPIRE_DATE=`date -d "${NOTAFTER#notAfter=}" "+%Y年%m月%d日-%H時%M分%S秒-JST"`
	echo ${EXPIRE_DATE}

    # 通知メッセージかつ、MyOpenSSL関数の戻り値
    RESULT=${RESULT_EXPIRE}

    # 積算
    OPENSSL_RET_VALUE=$((OPENSSL_RET_VALUE+1))

}

Notification_Not_Expire() {
    # 期限切れが間近ではない
    echo ${RESULT_NOT_EXPIRE}

	# 有効期限
	NOTAFTER=`grep notAfter ${HOME}cacert-${HOST}.txt`
	echo ${NOTAFTER}    # notAfter=Aug 8 23:59:59 2021 GMT
    # "notAfter=" を削除して日本語でJST表示
	EXPIRE_DATE=`date -d "${NOTAFTER#notAfter=}" "+%Y年%m月%d日-%H時%M分%S秒-JST"`
	echo ${EXPIRE_DATE}

    # 通知メッセージかつ、MyOpenSSL関数の戻り値
    RESULT=${RESULT_NOT_EXPIRE}

    # OPENSSL_RET_VALUE は積算しない
}

Notification_Unable_To_Load() {
    # 証明書を取得できなかった
    echo ${RESULT_UNABLE_TO_LOAD}

	# 有効期限
	EXPIRE_DATE="NotAvailable"

    # 通知メッセージかつ、MyOpenSSL関数の戻り値
    RESULT=${RESULT_UNABLE_TO_LOAD}

    # 積算
    OPENSSL_RET_VALUE=$((OPENSSL_RET_VALUE+1))
}

SendMsgToTeams() {
    # $1 HOST
    # $2 EXPIRE_DATE
    # $3 RESULT

    echo "SendMsgToTeams() に入りました"
    echo HOST:$1, EXPIRE_DATE:$2, RESULT:$3

    # Teams の Webhook に通知
    # 更新間近があるか、取得できなかった場合
    echo "SendMsgToTeams() 内の OPENSSL_RET_VALUE: "$((OPENSSL_RET_VALUE))
    # echo {${HOST}, ${NOTAFTER}, ${RESULT}} >> ${HOME}cacert-${HOST}.txt
    echo {$1, $2, $3} >> ${HOME}cacert-$1.txt
    echo "SendMsgToTeams() から、curl を実行します"

    curl -x gwproxy.daikin.co.jp:3128 -H 'Accept: application/json' -H "Content-type: application/json" -X POST \
    	 -d '{"title": "'$TITLE'", "text": "- Host='$1'\n\n- NotAfter='$2'\n\n- Result='$3'"}' ${CERTCHECK_URL}

}

# ---------- 開始： サーバー一覧ファイル list-hosts.csv 記載のサーバを1つずつ検証 ----------
# 実施日の取得
TODAY=`date +%Y年%m月%d日`

# タイトルに実施日追記
TITLE="${TITLE}"'（'"${TODAY}"'）'

echo "Start "$0
SKIP="ON"   # skip 1st line
while read line; do
    if [ "${SKIP}" != "ON" ]; then
        HOST=`echo ${line} | cut -d ',' -f 1`        # -d デリミタ, -f フィールド番号（列）
        PORT=`echo ${line} | cut -d ',' -f 2`
        SERVICE=`echo ${line} | cut -d ',' -f 3`

        # echo "Host: ${HOST}"
        # echo "Port: ${PORT}"
        # echo "Service: ${SERVICE}"
        # echo ""

        echo "----- ${HOST}:${PORT} - ${SERVICE} -----"
        echo "----- ${HOST}:${PORT} - ${SERVICE} -----" > ${HOME}cacert-${HOST}.txt
        MyOpenSSL ${HOST} ${PORT} ${SERVICE}

        # 更新間近の場合のみ、Teams に通知（サーバーごと）
        case ${RESULT} in
            "${RESULT_EXPIRE}")
                # 更新間近な場合（と、証明書を取得できない場合）は、通知する
                SendMsgToTeams ${HOST} ${EXPIRE_DATE} ${RESULT}
                ;;

            "${RESULT_NOT_EXPIRE}")
                # 更新間近でない場合は、通知しない
                echo "更新間近でないので通知しません"
                ;;

            "${RESULT_UNABLE_TO_LOAD}")
                # （更新間近な場合と、）証明書を取得できない場合は、通知する
                SendMsgToTeams ${HOST} ${EXPIRE_DATE} ${RESULT}
                ;;

            *)
                # ありえない場合は、通知しない
                echo "ありえないケースですので通知しません"
                ;;
        esac

    fi

    SKIP=""
    echo "."
done < $URLList

# 更新間近と証明書の取得不可がなかったら、Teams の Webhook にその旨を通知
echo "Main() 内の OPENSSL_RET_VALUE: "$((OPENSSL_RET_VALUE))
if [ $((OPENSSL_RET_VALUE)) -eq 0 ]; then
    echo "OPENSSL_RET_VALUE が 0 なので、Main() から、curl を実行し、MESS_NO_EXPIRE を通知します"

    curl -x gwproxy.daikin.co.jp:3128 -H 'Accept: application/json' -H "Content-type: application/json" -X POST \
	 	 -d '{"title": "'$TITLE'", "text": "'$MESS_NO_EXPIRE'"}' ${CERTCHECK_URL}

    echo '{"title": "'$TITLE'", "text": "'$MESS_NO_EXPIRE'"}'
else
    echo "OPENSSL_RET_VALUE が 0 でないので、MESS_NO_EXPIRE を通知しません"

fi

# ログファイル移動
LOGDIR=`date +%Y%m%d%H%M`
mkdir -p /home/vuls/CAcert/cacert-result/$LOGDIR
# mv ${HOME}cacert*.log ${HOME}cacert-result/$LOGDIR
mv ${HOME}cacert*.txt ${HOME}cacert-result/$LOGDIR

# Zドライブへディレクトリごと（-r）コピー
cp -r ${HOME}cacert-result/$LOGDIR/ $Z_LOG_DIR

#  ---------- 終了 ----------