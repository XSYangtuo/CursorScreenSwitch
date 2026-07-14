<#
.SYNOPSIS
  CursorScreenSwitch — 双屏光标快速跳转 CLI

.DESCRIPTION
  管理 AHK 后台脚本，控制光标在双屏间跳转。

  命令:
    on / start     启动光标切换
    off / stop     关闭光标切换
    toggle         切换开关状态
    status         查看运行状态
    restart / reload  重载配置后重启
    config / edit  编辑配置文件（记事本打开）

.EXAMPLE
  .\cursor_sw.ps1 on
  .\cursor_sw.ps1 status
  .\cursor_sw.ps1 toggle
#>

param(
    [Parameter(Position = 0)]
    [string]$Command = 'status'
)

$ScriptName   = "CursorScreenSwitch"
$AhkScript    = Join-Path $PSScriptRoot "cursor_sw.ahk"
$ConfigFile   = Join-Path $PSScriptRoot "config.ini"
$AhkPaths     = @(
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey.exe"
)

# ---- 辅助函数 ----

function Write-Status {
    param([string]$Text, [string]$Color = "White")
    Write-Host "  $Text" -ForegroundColor $Color
}

function Write-Ok    { Write-Host "  ✓ " -ForegroundColor Green -NoNewline; Write-Host $args[0] }
function Write-Fail  { Write-Host "  ✗ " -ForegroundColor Red   -NoNewline; Write-Host $args[0] }

function Get-ScriptProcess {
    Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" |
        Where-Object { $_.CommandLine -match [regex]::Escape($AhkScript) }
}

function Find-AhkExe {
    foreach ($p in $AhkPaths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Read-HotkeyFromConfig {
    if (!(Test-Path $ConfigFile)) { return "unknown" }
    $ini = Get-Content $ConfigFile -Raw -Encoding UTF8
    if ($ini -match '(?m)^switch_screen=(.+)') {
        $hotkey = $matches[1].Trim()
        # 翻译修饰符为人类可读（+ 优先替换，避免后续替换误伤）
        $hotkey = $hotkey -replace '\+', 'Shift+'
        $hotkey = $hotkey -replace '\^', 'Ctrl+'
        $hotkey = $hotkey -replace '!', 'Alt+'
        $hotkey = $hotkey -replace '#', 'Win+'
        return $hotkey
    }
    return "unknown"
}

# ---- 主逻辑 ----

$process = Get-ScriptProcess
$ahkExe  = Find-AhkExe

switch -Wildcard ($Command.ToLower()) {
    { $_ -in 'on', 'start' } {
        if ($process) {
            Write-Ok "$ScriptName 已在运行中 (PID: $($process.ProcessId))"
            exit 0
        }
        if (!$ahkExe) {
            Write-Fail "未找到 AutoHotkey v2，请先安装 https://www.autohotkey.com/"
            exit 1
        }
        Start-Process $ahkExe -ArgumentList "`"$AhkScript`""
        Start-Sleep 0.5
        $process = Get-ScriptProcess
        if ($process) {
            $hk = Read-HotkeyFromConfig
            Write-Ok "$ScriptName 已启动"
            Write-Status "快捷键 $hk  (PID: $($process.ProcessId))" -Color Cyan
        } else {
            Write-Fail "启动失败"
            exit 1
        }
    }

    { $_ -in 'off', 'stop' } {
        if (!$process) {
            Write-Status "$ScriptName 未运行" -Color Yellow
            exit 0
        }
        $procId = $process.ProcessId
        Stop-Process -Id $procId -Force
        Start-Sleep 0.3
        $process = Get-ScriptProcess
        if (!$process) {
            Write-Ok "$ScriptName 已关闭"
        } else {
            Write-Fail "关闭失败"
            exit 1
        }
    }

    'toggle' {
        if ($process) {
            & $PSCommandPath off
        } else {
            & $PSCommandPath on
        }
    }

    { $_ -in 'restart', 'reload' } {
        if ($process) {
            $oldPid = $process.ProcessId
            Stop-Process -Id $oldPid -Force
            Start-Sleep 0.5
        }
        if (!$ahkExe) {
            Write-Fail "未找到 AutoHotkey v2"
            exit 1
        }
        Start-Process $ahkExe -ArgumentList "`"$AhkScript`""
        Start-Sleep 0.5
        $process = Get-ScriptProcess
        if ($process) {
            $hk = Read-HotkeyFromConfig
            Write-Ok "$ScriptName 已重新加载"
            Write-Status "快捷键 $hk  (PID: $($process.ProcessId))" -Color Cyan
        } else {
            Write-Fail "重载失败"
            exit 1
        }
    }

    { $_ -in 'config', 'edit' } {
        if (Test-Path $ConfigFile) {
            Start-Process notepad $ConfigFile
            Write-Ok "已打开配置文件"
        } else {
            Write-Fail "配置文件不存在: $ConfigFile"
            exit 1
        }
    }

    'layout' {
        try {
            Add-Type -AssemblyName System.Windows.Forms
        } catch {
            Write-Fail "无法加载显示器信息"
            exit 1
        }
        $screens = [System.Windows.Forms.Screen]::AllScreens
        Write-Host ""
        Write-Host "  $ScriptName — 显示器布局" -ForegroundColor Cyan
        Write-Host "  =============================================" -ForegroundColor DarkGray
        $i = 1
        foreach ($s in $screens) {
            $b = $s.Bounds
            $origin = if ($s.Primary) { "  ← 主屏 (0,0)" } else { "" }
            $res = "{0}×{1}" -f $b.Width, $b.Height
            Write-Host "    #$i  [$($b.X), $($b.Y) ~ $($b.Right), $($b.Bottom)]  $res$origin" -ForegroundColor White
            $i++
        }
        Write-Host ""
        Write-Status "在 layout.ini 的 order= 中按 # 编号指定跳转顺序" -Color DarkGray
        Write-Status "  cursor_sw config  打开配置文件" -Color DarkGray
        Write-Host ""
    }

    { $_ -in 'status', 'help', '--help', '-h', '-?' } {
        if ($Command -in 'help', '--help', '-h', '-?') {
            Write-Host "╭─ $ScriptName CLI ──────────────────────────────╮" -ForegroundColor Cyan
            Write-Host "│" -ForegroundColor Cyan -NoNewline
            Write-Host "  命令:                                      " -NoNewline
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "│" -ForegroundColor Cyan -NoNewline
            Write-Host "  on / start    启动光标切换                     " -NoNewline
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "│" -ForegroundColor Cyan -NoNewline
            Write-Host "  off / stop    关闭光标切换                     " -NoNewline
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "│" -ForegroundColor Cyan -NoNewline
            Write-Host "  toggle        切换开关                         " -NoNewline
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "│" -ForegroundColor Cyan -NoNewline
            Write-Host "  status        查看运行状态                     " -NoNewline
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "│" -ForegroundColor Cyan -NoNewline
            Write-Host "  restart/reload 重载配置后重启                  " -NoNewline
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "│" -ForegroundColor Cyan -NoNewline
            Write-Host "  config/edit   编辑配置                         " -NoNewline
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "│" -ForegroundColor Cyan -NoNewline
            Write-Host "  layout        查看显示器布局与编号             " -NoNewline
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "╰──────────────────────────────────────────────╯" -ForegroundColor Cyan
            exit 0
        }

        # status
        if ($process) {
            $hk = Read-HotkeyFromConfig
            $proc = Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue
            $uptime = if ($proc) { (Get-Date) - $proc.StartTime } else { [TimeSpan]::Zero }
            $uptimeStr = "{0}小时{1}分" -f $uptime.Hours, $uptime.Minutes
            Write-Host ""
            Write-Host "  [ON]  $ScriptName  运行中" -ForegroundColor Green
            Write-Host "       快捷键  $hk" -ForegroundColor Cyan
            Write-Host "       PID     $($process.ProcessId)" -ForegroundColor DarkGray
            Write-Host "       运行    $uptimeStr" -ForegroundColor DarkGray
            Write-Host ""
            Write-Status "cursor_sw off     关闭" -Color DarkGray
            Write-Status "cursor_sw toggle  切换" -Color DarkGray
            Write-Status "cursor_sw config  编辑配置" -Color DarkGray
            Write-Status "cursor_sw layout 显示器布局" -Color DarkGray
        } else {
            Write-Host ""
            Write-Host "  [OFF]  $ScriptName  未运行" -ForegroundColor Yellow
            Write-Host ""
            Write-Status "cursor_sw on   启动" -Color DarkGray
            Write-Status "cursor_sw config  编辑配置" -Color DarkGray
        }
        Write-Host ""
    }

    default {
        Write-Fail "未知命令: $Command"
        Write-Status "可用命令: on, off, toggle, status, restart, config, layout" -Color DarkGray
        exit 1
    }
}
