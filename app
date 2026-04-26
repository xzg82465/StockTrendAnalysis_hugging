import gradio as gr
from datetime import datetime
import time

import yfinance as yf
import pandas as pd
import requests
from io import StringIO



def run_all(tickersymbol, download_data, download_update, use_train, method):
    # 1. 產生設定參數摘要
    config_str = f"股票代碼：{tickersymbol}\n"
    config_str += f"更新資料：{'是' if download_data else '否'} (日期: {download_update})\n"
    config_str += f"啟用訓練：{'是' if use_train else '否'} (方式: {method})"
    # 第一次 yield：先更新參數顯示區，Log 區暫時顯示「準備中」
    yield config_str


def update_setup(is_checked):
    # 根據 UPDATE_DATA 的布林值決定 end_date 是否顯示
    return gr.update(visible=is_checked)

def train_setup(is_checked):
    # 根據 TRAIN 的布林值決定 LOSS_FN 是否顯示
    return gr.update(visible=is_checked)

def predict_setup(is_checked):
    # 根據 PREDICT 的布林值決定 predict_date 是否顯示
    return gr.update(visible=is_checked)

choices_list = []

# 如果沒有 tickers，提供備選項
if not choices_list:
    choices_list = ["No tickers loaded"]
    print("Warning: tw50_tickers is empty!")


with gr.Blocks() as demo:
    gr.Markdown("### 股票分析與訓練設定")
    
    with gr.Row():
        ticker_list = gr.Dropdown(
            choices = choices_list, 
            label = "股票代碼",
            value = choices_list[0] if choices_list else None
        )## 1. 股票代碼下拉選單
        
    with gr.Row():        
        UPDATE_DATA = gr.Checkbox(label="更新資料", value=False) # 更新功能勾選框
        
        end_date = gr.DateTime(
            label = "選擇數據更新日",
            include_time = False,  # 股票分析通常不需時間
            type = "string",       # 直接傳回 "YYYY-MM-DD" 字串，方便後續 API 使用
            value = lambda: datetime.now().strftime("%Y-%m-%d"), # 預設為今天
            visible = False
        ) #日期元件（資料日期 visible=False)

    with gr.Row():    
        PREDICT = gr.Checkbox(label="啟用預測功能", value=False) #預測功能勾選框
        
        predict_date = gr.DateTime(
            label = "選擇預測日期",
            include_time = False, 
            type = "string",       # 直接傳回 "YYYY-MM-DD" 字串，方便後續 API 使用
            value = lambda: datetime.now().strftime("%Y-%m-%d"), # 預設為今天
            visible = False
        ) # 日期元件（資料日期 visible=False)
        
    with gr.Row():    
        TRAIN = gr.Checkbox(label="啟用訓練功能", value=False) ## 訓練功能勾選框
        
        LOSS_FN = gr.Radio(
            choices = ["ce", "focal", "madl_focal"], 
            label = "訓練方式", 
            value = "ce",
            visible = False
        ) #單選按鈕(訓練法設定 visible=False)
    


    with gr.Row():
        run_btn = gr.Button("啟動")
    
    
    UPDATE_DATA.change(
        fn = update_setup, 
        inputs = UPDATE_DATA, 
        outputs = end_date
    )# --- 日期隱藏：UPDATE_DATA 狀態改變時，更新 end_date 的可見性
        
    TRAIN.change(
        fn = train_setup, 
        inputs = TRAIN, 
        outputs = LOSS_FN
    )# --- 訓練法隱藏：當 TRAIN 狀態改變時，更新 LOSS_FN 的可見性

    PREDICT.change(
        fn = predict_setup, 
        inputs = PREDICT, 
        outputs = predict_date
    )# --- 預測功能隱藏：當 PREDICT 狀態改變時，更新 predict_date 的可見性
  
        # --- 兩個輸出欄位 ---
    # 一：顯示設定
    config_display = gr.Textbox(label="目前設定參數", lines=4)

    # 二：終端機
    # 使用 Textbox 模擬 Console，設定 lines=20 讓它看起來像個視窗
    console_output = gr.Textbox(
        label="Terminal Console",
        placeholder="",
        lines=20,
        max_lines=100,
        interactive=False,
        elem_classes=["terminal"] # 套用自定義的 CSS
    )
    # 執行按鈕的邏輯
    run_btn.click(
        fn = run_all, 
        inputs = [ticker_list, UPDATE_DATA, end_date, TRAIN, LOSS_FN], 
        outputs = [config_display] # 這裡依序對應 yield 的回傳值
    )
    
demo.launch()
