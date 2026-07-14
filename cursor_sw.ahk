#Requires AutoHotkey v2.0
#SingleInstance Force

; =============================================================================
;  CursorScreenSwitch  —  双屏光标快速跳转
;  快捷键默认 Ctrl+Alt+`，可在 config.ini 中修改
;  快捷键触发后会在光标位置显示 1.5s 跳转坐标，用于排查副屏中心偏移问题
; =============================================================================

; ---- DPI 感知（避免多屏缩放不一致导致坐标偏移）----
; Win 8.1+ 尝试 Per-Monitor Aware，失败则静默跳过
; Win 7 及以下忽略，不影响核心功能
try {
    DllCall("Shcore.dll\SetProcessDpiAwareness", "int", 2)
} catch {
    ; Shcore.dll 不存在或调用失败，不做特殊处理
}

; ---- 读取配置 ----
configFile := A_ScriptDir "\config.ini"

; 快捷键（默认 ^!` = Ctrl+Alt+`）
switchHotkey := IniRead(configFile, "Hotkeys", "switch_screen", "^!``")

; 移动速度（0 瞬间，>0 带动画）
moveSpeed := IniRead(configFile, "Behavior", "move_speed", "0")

; 托盘图标
showIcon := IniRead(configFile, "General", "show_tray_icon", "1")
if (showIcon = "0") {
    TraySetIcon()
}

; ---- 注册快捷键 ----
Hotkey switchHotkey, SwitchScreen

; =============================================================================
;  核心：交换到另一屏幕中心
; =============================================================================
SwitchScreen(*) {
    ; 检测显示器数量
    count := MonitorGetCount()
    if (count < 2) {
        TrayTip "CursorScreenSwitch: 检测到 " count " 个显示器，需要至少 2 个"
        return
    }

    ; 获取两个显示器的边界
    ; MonitorGet 返回屏幕坐标系的 Left, Top, Right, Bottom
    MonitorGet 1, &X1, &Y1, &X2, &Y2
    MonitorGet 2, &X3, &Y3, &X4, &Y4

    ; 真正的物理主屏是包含原点 (0,0) 的那个
    ; （Windows 坐标系中，主显示器左上角始终为 (0,0)）
    if (X1 <= 0 && X2 > 0 && Y1 <= 0 && Y2 > 0) {
        ; Monitor 1 是物理主屏
        priL := X1, priT := Y1, priR := X2, priB := Y2
        secL := X3, secT := Y3, secR := X4, secB := Y4
    } else {
        ; Monitor 2 是物理主屏
        priL := X3, priT := Y3, priR := X4, priB := Y4
        secL := X1, secT := Y1, secR := X2, secB := Y2
    }

    ; 获取鼠标当前位置（屏幕坐标）
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my

    ; 判断鼠标在哪个屏幕，目标设到另一屏幕中心
    if (mx >= priL && mx <= priR && my >= priT && my <= priB) {
        ; 光标在主屏 → 跳到副屏中心
        targetX := (secL + secR) // 2
        targetY := (secT + secB) // 2
        debugMonitor := "副屏"
        debugBounds := "[" . secL . ", " . secT . " ~ " . secR . ", " . secB . "]"
    } else {
        ; 光标在副屏 → 跳到主屏中心
        targetX := (priL + priR) // 2
        targetY := (priT + priB) // 2
        debugMonitor := "主屏"
        debugBounds := "[" . priL . ", " . priT . " ~ " . priR . ", " . priB . "]"
    }

    ; 移动光标（Windows API，不受 DPI 虚拟化影响）
    DllCall("SetCursorPos", "int", targetX, "int", targetY)

    ; 验证：移动后立刻读取实际光标位置
    Sleep 50
    MouseGetPos &actualX, &actualY
    matchStr := ""
    if (actualX != targetX || actualY != targetY) {
        matchStr := "  [偏差! 实际 " actualX ", " actualY "]"
    }

    ; 调试信息：显示 1.5 秒
    ToolTip "CursorScreenSwitch`n→ " debugMonitor " ( " targetX ", " targetY " )" matchStr "`n  边界 " debugBounds
    SetTimer () => ToolTip(), -1500
}

Persistent
