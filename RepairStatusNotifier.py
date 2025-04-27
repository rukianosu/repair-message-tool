import streamlit as st
from datetime import datetime, timedelta
import pyperclip

st.title("修理完了連絡用メッセージ作成ツール")

# セッションステートでフォーム管理
if 'template' not in st.session_state:
    st.session_state.template = ""

# 今日と明日の日付
today = datetime.today()
day = today.day

tomorrow = today + timedelta(days=1)
tomorrow_day = tomorrow.day

# 運送会社の選択（ゆうパック削除済み）
carrier = st.radio("運送会社を選んでください", ("ヤマト運輸", "佐川急便"))

# 支払い方法の選択
payment_method = st.radio("支払い方法を選んでください", ("銀行振込", "代引き", "着払い"))

# 配達希望時間帯の選択
if carrier == "ヤマト運輸":
    time_slot = st.radio(
        "配達希望時間帯を選んでください", 
        ("午前中", "14時～16時", "16時～18時", "18時～20時", "19時～21時")
    )
elif carrier == "佐川急便":
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

# ボタンを並べて表示
col1, col2 = st.columns(2)

with col1:
    if st.button("メッセージを作成"):
        # 運送会社ごとのリンク作成（ここ修正済み！）
        if carrier == "ヤマト運輸":
            tracking_link = f"https://jizen.kuronekoyamato.co.jp/jizen/servlet/crjz.b.NQ0010?id={tracking_number}"
        elif carrier == "佐川急便":
            tracking_link = f"https://k2k.sagawa-exp.co.jp/p/web/okurijosearch.do?okurijoNo={tracking_number}"
        else:
            tracking_link = ""

        # 金額整形（カンマあり）
        try:
            total_price = int(total_price_input.replace(",", ""))
            total_price_str = f"{total_price:,}"
        except:
            st.error("金額の入力が正しくありません。数字だけ、またはカンマ付きで入力してください。")
            st.stop()

        # 支払い方法によるメッセージ分岐
        if payment_method == "銀行振込":
            price_suffix = "（消費税込み）"
            message_body = f"""
お世話になっております。
パソコン修理のルキテック　橘です。

修理のご依頼をいただき、誠にありがとうございました。
心より感謝申し上げます。

お預かりのパソコン修理が完了致しました。
本日　4/{day}　発送となります。
到着までしばらくお待ちくださいませ。

{carrier}　問合せ番号　{tracking_number}
{tracking_link}
※web上でご確認いただけるまで時間がかかります。

▼修理内容
---------------------------------
{repair_detail}

▼修理代金
合計　　　　{total_price_str}円{price_suffix}

明日{tomorrow_day}日 {time_slot} 配達指定なので到着すると思いますので、動作チェックをお願いいたします。
運送会社の都合により時間帯のご希望に添えない場合はあるので事前にご了承をお願いいたします。

パソコン到着後、すぐに動作を確認してください。
何かご質問等ありましたら、お気軽にお問合せくださいませ。

今後ともよろしくお願いいたします。
            """
        
        elif payment_method == "代引き":
            price_suffix = "（代引き手数料及び消費税込み）"
            message_body = f"""
お世話になっております。
パソコン修理のルキテック　橘です。

修理のご依頼をいただき、誠にありがとうございました。
心より感謝申し上げます。

お預かりのパソコン修理が完了致しました。
本日　4/{day}　発送となります。
到着までしばらくお待ちくださいませ。

{carrier}　問合せ番号　{tracking_number}
{tracking_link}
※web上でご確認いただけるまで時間がかかります。

▼修理内容
---------------------------------
{repair_detail}

▼修理代金
合計　　　　{total_price_str}円{price_suffix}

明日{tomorrow_day}日 {time_slot} 配達指定なので到着すると思いますので、動作チェックをお願いいたします。
運送会社の都合により時間帯のご希望に添えない場合はあるので事前にご了承をお願いいたします。

パソコン到着後、すぐに動作を確認してください。
何かご質問等ありましたら、お気軽にお問合せくださいませ。

今後ともよろしくお願いいたします。
            """

        elif payment_method == "着払い":
            # 着払い専用テンプレート
            message_body = f"""
お世話になっております。
パソコン修理・データ復旧のルキテック　橘です。

パソコン修理のご期待にお応えすることが出来ず申し訳ございませんでした。

お預かりのパソコンをご返却いたします。
本日　4/{day}　発送となります。
到着までしばらくお待ちくださいませ。

{carrier}　問合せ番号　{tracking_number}
{tracking_link}
※web上でご確認いただけるまで時間がかかります。

▼修理内容
修理中断

▼修理代金
合計　　　　{total_price_str}円（着払い送料並びに代引き手数料及び消費税込み）

着払いでの返送となります。

明日{tomorrow_day}日 {time_slot} 配達指定なので到着すると思いますので、検品をお願いいたします。

何かご質問等ありましたら、お気軽にお問合せくださいませ。
            """

        else:
            message_body = "支払い方法にエラーがあります。"

        # メッセージ保存
        st.session_state.template = message_body
        st.success("メッセージが作成されました！🎉")

with col2:
    if st.button("クリアする"):
        st.session_state.template = ""
        st.rerun()

# メッセージ表示とコピーボタン
if st.session_state.template:
    st.text_area("完成したメッセージ（編集可能・ここからコピー！）", st.session_state.template, height=800)
    
    if st.button("📋 コピーする"):
        pyperclip.copy(st.session_state.template)
        st.success("メッセージをクリップボードにコピーしました！✨")

