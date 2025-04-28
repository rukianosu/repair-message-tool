import streamlit as st
from datetime import datetime, timedelta

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

# 配達指定日の入力
specified_date_input = st.text_input("配達指定日を入力してください（例：5/5）※未入力なら明日になります")

# メッセージ作成ボタン
if st.button("メッセージを作成"):
    # 配達指定日のセット
    if specified_date_input:
        specified_date = specified_date_input
    else:
        specified_date = f"{tomorrow_month}/{tomorrow_day}"

    # 支払い方法による表記
    if payment_method == "銀行振込":
        price_suffix = "（消費税込み）"
    elif payment_method == "代引き":
        price_suffix = "（代引き手数料および消費税込み）"
    else:
        price_suffix = "（着払い送料・代引き手数料および消費税込み）"

    # 金額整形
    try:
        total_price = int(total_price_input.replace(",", ""))
        total_price_str = f"{total_price:,}"
    except:
        st.error("金額の入力が正しくありません。数字だけ、またはカンマ付きで入力してください。")
        st.stop()

    # 送り状リンク
    if carrier == "ヤマト運輸":
        tracking_link = f"https://jizen.kuronekoyamato.co.jp/jizen/servlet/crjz.b.NQ0010?id={tracking_number}"
    else:
        tracking_link = f"https://k2k.sagawa-exp.co.jp/p/web/okurijosearch.do?okurijoNo={tracking_number}"

    # 支払い方法による文章分岐
    if payment_method == "着払い":
        main_message = "パソコン修理のご期待にお応えすることが出来ず、誠に申し訳ございませんでした。\nお預かりしていたパソコンをご返却させていただきます。"
        repair_text = "修理中断"
        action_sentence = "到着後、検品をお願い申し上げます。"
    else:
        main_message = "修理のご依頼をいただき、誠にありがとうございました。\nお預かりしていたパソコンの修理が完了いたしました。"
        repair_text = repair_detail
        action_sentence = "到着後、動作のご確認をお願い申し上げます。"

    # --- メッセージ本文作成 ---
    message = f"""お世話になっております。
パソコン修理のルキテック　スタッフです。

{main_message}

本日　{month}月{day}日　発送となります。
到着までしばらくお待ちくださいませ。

{carrier}　お問い合わせ番号　{tracking_number}
{tracking_link}
※Web上でご確認いただけるまでに時間がかかる場合がございます。

▼修理内容
---------------------------------
{repair_text}

▼修理代金
合計　　　　{total_price_str}円{price_suffix}

{specified_date} {time_slot} 配達予定となっております。{action_sentence}
運送会社の都合によりご希望の時間帯にお届けできない場合がございますので、あらかじめご了承ください。

パソコン到着後は、速やかにご確認をお願いいたします。
何かご不明な点がございましたら、お気軽にお問い合わせくださいませ。

今後ともよろしくお願い申し上げます。
"""

    # --- メッセージ表示 ---
    st.text_area("完成したメッセージ（ここから手動でコピーしてください）", message, height=800)
