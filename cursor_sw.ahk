#Requires AutoHotkey v2.0
#SingleInstance Force

; =============================================================================
;  CursorScreenSwitch  —  多屏光标循环跳转
;  快捷键默认 Ctrl+Alt+`，可在 config.ini 中修改
;  跳转顺序在 layout.ini 中配置
; =============================================================================

; ---- DPI 感知（避免多屏缩放不一致导致坐标偏移）----
; Win 8.1+ 尝试 Per-Monitor Aware，失败则静默跳过
try {
    DllCall("Shcore.dll\SetProcessDpiAwareness", "int", 2)
} catch {
    ; 不支持的系统（Win 7 等），不做特殊处理
}

; ---- 读取配置 ----
configFile := A_ScriptDir "\config.ini"
layoutFile  := A_ScriptDir "\layout.ini"

; 快捷键（默认 ^!` = Ctrl+Alt+`）
switchHotkey := IniRead(configFile, "Hotkeys", "switch_screen", "^!``")



; 托盘图标
showIcon := IniRead(configFile, "General", "show_tray_icon", "1")
if (showIcon = "0") {
    TraySetIcon()
}

; ---- 注册快捷键 ----
Hotkey switchHotkey, SwitchScreen

; =============================================================================
;  核心：按 cycle 顺序跳到下一块屏幕的中心
; =============================================================================
SwitchScreen(*) {
    count := MonitorGetCount()
    if (count < 2) {
        TrayTip "CursorScreenSwitch: 检测到 " count " 个显示器，需要至少 2 个"
        return
    }

    ; ---- 读取循环顺序 ----
    orderStr := ""
    try {
        orderStr := IniRead(layoutFile, "MonitorCycle", "order", "")
    }
    orderList := []
    if (Trim(orderStr) = "") {
        ; 默认 1, 2, 3, ... count
        Loop count
            orderList.Push(A_Index)
    } else {
        ; 解析用户指定的顺序
        for item in StrSplit(orderStr, ",") {
            n := Integer(Trim(item))
            if (n >= 1 && n <= count)
                orderList.Push(n)
        }
        ; 如果全部被过滤掉（比如写了不存在的编号），回退到默认
        if (orderList.Length = 0) {
            Loop count
                orderList.Push(A_Index)
        }
    }

    ; ---- 获取所有屏幕边界 ----
    monitorBounds := []
    Loop count {
        MonitorGet A_Index, &L, &T, &R, &B
        monitorBounds.Push({l: L, t: T, r: R, b: B})
    }

    ; ---- 找光标所在屏幕 ----
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my

    currentIdx := -1
    for idx, monIdx in orderList {
        b := monitorBounds[monIdx]
        if (mx >= b.l && mx <= b.r && my >= b.t && my <= b.b) {
            currentIdx := idx
            break
        }
    }
    if (currentIdx = -1) {
        ; 光标不在任何已知屏幕（罕见情况），跳到第一个
        currentIdx := 1
    }

    ; ---- 计算下一个屏幕 ----
    nextOrderIdx := Mod(currentIdx, orderList.Length) + 1
    nextMonIdx   := orderList[nextOrderIdx]
    target       := monitorBounds[nextMonIdx]

    targetX := (target.l + target.r) // 2
    targetY := (target.t + target.b) // 2

    ; ---- 移动光标 ----
    DllCall("SetCursorPos", "int", targetX, "int", targetY)

    ; ---- 调试信息 1.5 秒 ----
    ToolTip "CursorScreenSwitch`n→ 屏幕 #" nextMonIdx " ( " targetX ", " targetY " )`n  边界 [" target.l ", " target.t " ~ " target.r ", " target.b "]"
    SetTimer () => ToolTip(), -1500
}

Persistent
