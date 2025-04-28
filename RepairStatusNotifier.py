import streamlit as st
from datetime import datetime, timedelta
import pyperclip

st.title("修理完了連絡用メッセージ作成ツール")

# 今日と明日の日付＋月
today = datetime.today()
month = today.month
day = today.day

tomorrow = today + timedelta(days=1)
tomorrow_month = tomorrow.month
tomorrow_day = tomorrow.day

# 運送会社の選択
carrier = st.radio("運送会社を選んでください", ("ヤマト運輸", "佐川急便"))

# 支払い方法の選択
payment_method = st.radio("支払い方法を選んでください", ("銀行振込", "代引き", "着払い"))

# 配達希望時間帯の選択
if carrier == "ヤマト運輸":
    time_slot = st.radio(
        "配達希望時間帯を選んでください",
        ("午前中", "14時～16時", "16時～18時", "18時～20時", "19時～21時")
    )
else:
    time_slot = st.radio(
        "配達希望時間帯を選んでください",
        ("午前中", "12時～14時", "14時～16時", "16時～18時", "18時～20時", "18時～21時", "19時～21時")
    )

# 送り状番号の入力
tracking_number = st.text_input("送り状番号を入力してください")

# 修理内容の入力
repair_detail = st.text_area("修理内容を入力してください", height=150)

# 合計金額の入力（カンマOK）
total_price_input = st.text_input("合計金額を入力してください（例：12,345）")

# 配達指定日入力（ここに移動！）
specified_date_input = st.text_input("配達指定日を入力してください（例：5/5）※未入力なら明日になります")

# ここでメッセージを作る
if st.button("メッセージを作成"):

    # 指定日が入力されていればそれを、なければ明日
    if specified_date_input:
        specified_date = specified_date_input
    else:
        specified_date = f"{tomorrow_month}/{tomorrow_day}"

    # 支払い方法による金額の表記
    if payment_method == "銀行振込":
        price_suffix = "（消費税込み）"
    elif payment_method == "代引き":
        price_suffix = "（代引き手数料及び消費税込み）"
    else:
        price_suffix = "（着払い送料並びに代引き手数料及び消費税込み）"

    # 金額整形
    try:
        total_price = int(total_price_input.replace(",", ""))
        total_price_str = f"{total_price:,}"
    except:
        st.error("金額の入力が正しくありません。数字だけ、またはカンマ付きで入力してください。")
        st.stop()

    # 運送会社のリンク
    if carrier == "ヤマト運輸":
        tracking_link = f"https://jizen.kuronekoyamato.co.jp/jizen/servlet/crjz.b.NQ0010?id={tracking_number}"
    else:
        tracking_link = f"https://k2k.sagawa-exp.co.jp/p/web/okurijosearch.do?okurijoNo={tracking_number}"

    # 本文作成
    if payment_method == "着払い":
        main_message = "パソコン修理のご期待にお応えすることが出来ず申し訳ございませんでした。\nお預かりのパソコンをご返却いたします。"
        repair_text = "修理中断"
        check_text = "検品"
    else:
        main_message = "修理のご依頼をいただき、誠にありがとうございました。\n心より感謝申し上げます。\nお預かりのパソコン修理が完了致しました。"
        repair_text = repair_detail
        check_text = "動作チェック"

    message = f"""お世話になっております。
パソコン修理のルキテック　スタッフです。

{main_message}

本日　{month}/{day}　発送となります。
到着までしばらくお待ちくださいませ。

{carrier}　問合せ番号　{tracking_number}
{tracking_link}
※web上でご確認いただけるまで時間がかかります。

▼修理内容
---------------------------------
{repair_text}

▼修理代金
合計　　　　{total_price_str}円{price_suffix}

{specified_date} {time_slot} 配達指定なので到着すると思いますので、{check_text}をお願いいたします。
運送会社の都合により時間帯のご希望に添えない場合はあるので事前にご了承をお願いいたします。

パソコン到着後、すぐに{check_text}してください。
何かご質問等ありましたら、お気軽にお問合せくださいませ。

今後ともよろしくお願いいたします。
"""

    st.session_state.template = message
    st.success("メッセージが作成されました！🎉")

# 出来上がったメッセージを表示・コピー
if 'template' in st.session_state and st.session_state.template:
    st.text_area("完成したメッセージ（ここからコピーできます）", st.session_state.template, height=800)
    
    if st.button("📋 コピーする"):
        pyperclip.copy(st.session_state.template)
        st.success("メッセージをクリップボードにコピーしました！✨")
