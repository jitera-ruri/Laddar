; DDDDDDDD-SX-T21-001 Rev.5
; XX130機器制御ラダー（フロー図サンプル1より）
; 左側・右側：異常処理含む完全版
; 中央：簡略版

;----------------------------------------
; 左側のフロー図（完全版）
;----------------------------------------
NETWORK 1
TITLE = "XX130 AUT/開 初期処理"
; 開始 → XX130 AUT/XX130 開
LD XX130_AUT
AND XX130_OPEN
OUT M0 ; 初期処理完了フラグ

NETWORK 2
TITLE = "NR判定"
; XX130 NRの判断
LD XX130_NR
OUT M1 ; NR判定結果

NETWORK 3
TITLE = "開判定"
; XX130 開の判断
LD M1
AND XX130_OPEN
OUT M2 ; 開判定結果

NETWORK 4
TITLE = "異常処理"
; アナンシェータ処理
LD M2
AND NOT AN11111111
OUT XXX_PROCESS_ERROR ; XXX工程異常
SET XXX_PROCESS_STOP_FL ; 一時停止FL ON

NETWORK 5
TITLE = "一時停止FL OFF判定"
; XXX工程一時停止FL OFFの判断
LD XXX_PROCESS_STOP_FL
AND NOT XXX_PROCESS_STOP_FL_OFF
OUT M3 ; FL OFF判定

NETWORK 6
TITLE = "ループ/復帰"
; FL OFFなら初期処理に戻る、ONなら異常処理ループ
LD M3
AND XXX_PROCESS_STOP_FL_OFF
OUT M0 ; 初期処理へ復帰

NETWORK 7
TITLE = "終了"
; NR判定がYまたは開判定がNなら終了
LD M1
OR NOT M2
OUT END1

;----------------------------------------
; 中央のフロー図（簡略版）
;----------------------------------------
NETWORK 8
TITLE = "中央フロー：初期処理"
LD XX130_AUT
AND XX130_OPEN
OUT M10

NETWORK 9
TITLE = "中央フロー：NR判定"
LD XX130_NR
OUT M11

NETWORK 10
TITLE = "中央フロー：開判定"
LD M11
AND XX130_OPEN
OUT M12

NETWORK 11
TITLE = "中央フロー：指定処理"
LD M12
OUT SPECIFIED_PROCESS

NETWORK 12
TITLE = "中央フロー：終了"
LD M11
OR NOT M12
OUT END2

;----------------------------------------
; 右側のフロー図（完全版）
; 左側と同一構造
;----------------------------------------
NETWORK 13
TITLE = "右側フロー：初期処理"
LD XX130_AUT
AND XX130_OPEN
OUT M20

NETWORK 14
TITLE = "右側フロー：NR判定"
LD XX130_NR
OUT M21

NETWORK 15
TITLE = "右側フロー：開判定"
LD M21
AND XX130_OPEN
OUT M22

NETWORK 16
TITLE = "右側フロー：異常処理"
LD M22
AND NOT AN11111111
OUT XXX_PROCESS_ERROR_R
SET XXX_PROCESS_STOP_FL_R

NETWORK 17
TITLE = "右側フロー：一時停止FL OFF判定"
LD XXX_PROCESS_STOP_FL_R
AND NOT XXX_PROCESS_STOP_FL_OFF_R
OUT M23

NETWORK 18
TITLE = "右側フロー：ループ/復帰"
LD M23
AND XXX_PROCESS_STOP_FL_OFF_R
OUT M20

NETWORK 19
TITLE = "右側フロー：終了"
LD M21
OR NOT M22
OUT END3

;----------------------------------------
; タグ情報
; XX130.MODZ.AUT, XX130.HSX.P2, XX130.ALRM.NR, XX130.PX.2
