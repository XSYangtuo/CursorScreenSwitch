#Requires AutoHotkey v2.0
#SingleInstance Force

; =============================================================================
;  Screen Switch  —  双屏光标快速跳转
;  快捷键默认 Ctrl+Alt+`，可在 config.ini 中修改
; =============================================================================

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
    ; 获取所有显示器的边界
    MonitorGet 1, &X1, &Y1, &X2, &Y2
    MonitorGet 2, &X3, &Y3, &X4, &Y4

    ; 获取鼠标当前位置（屏幕坐标）
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my

    ; 判断鼠标在哪个屏幕，目标设到另一屏幕中心
    if (mx >= X1 && mx <= X2 && my >= Y1 && my <= Y2) {
        targetX := (X3 + X4) // 2
        targetY := (Y3 + Y4) // 2
    } else {
        targetX := (X1 + X2) // 2
        targetY := (Y1 + Y2) // 2
    }

    ; 移动光标
    MouseMove targetX, targetY, moveSpeed
}

Persistent
