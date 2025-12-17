PROGRAM FlowchartSample
VAR
    (* フラグ変数 *)
    FeedFL: BOOL := FALSE;           (* 給液フラグ *)
    DrainFL: BOOL := FALSE;          (* 脱液フラグ *)
    ScrapeFL: BOOL := FALSE;         (* 掻取フラグ *)
    
    (* 弁制御 *)
    ZDD11521: BOOL := FALSE;         (* 給液弁 *)
    ZDD11522: BOOL := FALSE;         (* ケーキ洗浄弁 *)
    ZDD11523: BOOL := FALSE;         (* 濾布洗浄弁 *)
    ZDR11511: BOOL := FALSE;         (* ボトム弁 *)
    ZDR1151B: BOOL := FALSE;         (* N2弁 *)
    ZDD11524: BOOL := FALSE;         (* 排出弁 *)
    
    (* 回転制御 *)
    ZSQD11524: BOOL := FALSE;        (* 給液回転指令 *)
    ZSQD11525: BOOL := FALSE;        (* 脱液回転指令 *)
    ZSQD11521: BOOL := FALSE;        (* 給液FL *)
    ZSQD11522: BOOL := FALSE;        (* 脱液FL *)
    
    (* ポンプ制御 *)
    ZP1154: BOOL := FALSE;           (* リンズ液ポンプ *)
    
    (* センサー・計測値 *)
    ZSD1152_PX: INT := 0;            (* 回転数 *)
    
    (* タイマー *)
    ZTSS11526: TON;                  (* 待ちTM1 *)
    ZTSS11527: TON;                  (* N2パージTM *)
    ZTSS11521: TON;                  (* 待ちTM2 *)
    WaitTM1_Preset: TIME := T#10S;   (* 待ちTM1設定値 *)
    N2PurgeTM_Preset: TIME := T#5S;  (* N2パージTM設定値 *)
    WaitTM2_Preset: TIME := T#15S;   (* 待ちTM2設定値 *)
    N2PurgeTM_PH: INT := 0;          (* N2パージTM設定値(0=無効) *)
    
    (* 状態管理 *)
    FeedState: INT := 0;             (* 給液フロー状態 *)
    DrainState: INT := 0;            (* 脱液フロー状態 *)
    ScrapeState: INT := 0;           (* 掻取フロー状態 *)
    
    (* 開始トリガー *)
    StartFeed: BOOL := FALSE;        (* 給液開始 *)
    StartDrain: BOOL := FALSE;       (* 脱液開始 *)
    StartScrape: BOOL := FALSE;      (* 掻取開始 *)
    FeedEnd: BOOL := FALSE;          (* 給液終了信号 *)
    CakeWashEnd: BOOL := FALSE;      (* ケーキ洗浄終了信号 *)
END_VAR

(* ========================================= *)
(* 1. 給液フロー *)
(* ========================================= *)
IF StartFeed THEN
    CASE FeedState OF
        0: (* 給液準備 *)
            FeedFL := TRUE;
            DrainFL := FALSE;
            ScrapeFL := FALSE;
            FeedState := 1;
            
        1: (* 弁閉処理 *)
            ZDD11522 := FALSE;  (* ケーキ洗浄弁 閉 *)
            ZDD11523 := FALSE;  (* 濾布洗浄弁 閉 *)
            ZDR11511 := FALSE;  (* ボトム弁 閉 *)
            ZDR1151B := FALSE;  (* N2弁 閉 *)
            FeedState := 2;
            
        2: (* 給液回転指令 *)
            ZSQD11524 := TRUE;  (* 給液回転指令 FL ON *)
            FeedState := 3;
            
        3: (* 回転数チェック ≧300RPM *)
            IF ZSD1152_PX >= 300 THEN
                FeedState := 4;
            END_IF;
            
        4: (* 回転数チェック ≦600RPM *)
            IF ZSD1152_PX <= 600 THEN
                FeedState := 5;
            END_IF;
            
        5: (* ボトム弁 開 *)
            ZDR11511 := TRUE;
            FeedState := 6;
            
        6: (* 待ちTM1 START *)
            ZTSS11526(IN := TRUE, PT := WaitTM1_Preset);
            IF ZTSS11526.Q THEN
                FeedState := 7;
            END_IF;
            
        7: (* 給液弁 開 *)
            ZDD11521 := TRUE;
            ZTSS11526(IN := FALSE);  (* 待ちTM1 STOP *)
            FeedState := 8;
            
        8: (* 給液終了待ち *)
            IF FeedEnd THEN
                FeedState := 9;
            END_IF;
            
        9: (* ボトム弁 閉 *)
            ZDR11511 := FALSE;
            FeedState := 10;
            
        10: (* N2パージTMチェック *)
            IF N2PurgeTM_PH <> 0 THEN
                FeedState := 11;  (* N2パージ実行 *)
            ELSE
                FeedState := 15;  (* 待ちTM2へ *)
            END_IF;
            
        11: (* N2弁 開 *)
            ZDR1151B := TRUE;
            FeedState := 12;
            
        12: (* N2パージTM START *)
            ZTSS11527(IN := TRUE, PT := N2PurgeTM_Preset);
            IF ZTSS11527.Q THEN
                FeedState := 13;
            END_IF;
            
        13: (* N2弁 閉 *)
            ZDR1151B := FALSE;
            ZTSS11527(IN := FALSE);
            FeedState := 15;
            
        15: (* 待ちTM2 START *)
            ZTSS11521(IN := TRUE, PT := WaitTM2_Preset);
            IF ZTSS11521.Q THEN
                FeedState := 16;
            END_IF;
            
        16: (* 給液弁状態チェック *)
            IF ZDD11521 THEN
                ZDD11521 := FALSE;  (* 給液弁 閉 *)
            END_IF;
            ZTSS11521(IN := FALSE);
            FeedState := 17;
            
        17: (* リンズ液ポンプ 起動 *)
            ZP1154 := TRUE;
            FeedState := 18;
            
        18: (* 給液 FL OFF *)
            ZSQD11521 := FALSE;
            FeedState := 19;
            
        19: (* ZND - 終了 *)
            StartFeed := FALSE;
            FeedState := 0;
    END_CASE;
END_IF;

(* ========================================= *)
(* 2. 脱液フロー *)
(* ========================================= *)
IF StartDrain THEN
    CASE DrainState OF
        0: (* 脱液開始 *)
            FeedFL := FALSE;
            DrainFL := TRUE;
            ScrapeFL := FALSE;
            DrainState := 1;
            
        1: (* 弁閉処理 *)
            ZDD11521 := FALSE;  (* 給液弁 閉 *)
            ZDD11523 := FALSE;  (* 濾布洗浄弁 閉 *)
            DrainState := 2;
            
        2: (* 脱液回転指令 *)
            ZSQD11525 := TRUE;  (* 脱液回転指令 FL ON *)
            DrainState := 3;
            
        3: (* ケーキ洗浄 - リンズ液ポンプ起動 *)
            ZP1154 := TRUE;
            DrainState := 4;
            
        4: (* ケーキ洗浄弁 開 *)
            ZDD11522 := TRUE;
            DrainState := 5;
            
        5: (* ケーキ洗浄終了待ち *)
            IF CakeWashEnd THEN
                DrainState := 6;
            END_IF;
            
        6: (* ケーキ洗浄弁 閉 *)
            ZDD11522 := FALSE;
            DrainState := 7;
            
        7: (* 脱液 FL OFF *)
            ZSQD11522 := FALSE;
            DrainState := 8;
            
        8: (* ZND - 終了 *)
            StartDrain := FALSE;
            DrainState := 0;
    END_CASE;
END_IF;

(* ========================================= *)
(* 3. 掻取フロー *)
(* ========================================= *)
IF StartScrape THEN
    CASE ScrapeState OF
        0: (* 排出弁 開 *)
            ZDD11524 := TRUE;
            ScrapeState := 1;
            
        1: (* 排出弁 閉 *)
            ZDD11524 := FALSE;
            ScrapeState := 2;
            
        2: (* ZND - 終了 *)
            StartScrape := FALSE;
            ScrapeState := 0;
    END_CASE;
END_IF;

END_PROGRAM
