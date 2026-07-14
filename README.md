# Screen Switch 🖥️→🖥️

双屏光标快速跳转工具。按一个快捷键，光标瞬间从当前屏幕中心跳到另一屏幕中心。

## 适用场景

- 双屏（或更多）用户，经常需要在不同屏幕间快速切换鼠标操作
- 不想把鼠标拖过整个屏幕边界
- 配合键盘流工作流，减少手离开键盘的频次

## 环境要求

- Windows 7+
- [AutoHotkey v2](https://www.autohotkey.com/)（安装时选择默认路径即可）

## 快速开始

```bash
# 克隆到本地
git clone https://github.com/你的用户名/CursorScreenControl.git
cd CursorScreenControl

# 启动（CLI 方式，推荐）
.\screen-switch.cmd on

# 或双击 run.bat（自动查找 AHK 路径）
```

启动后按 **Ctrl + Alt + `**（反引号，数字 1 左边那个键）即可跳转光标。

## CLI 命令

```bash
screen-switch <command>
```

| 命令 | 说明 |
|------|------|
| `on` / `start` | 启动光标切换（加载 AHK 脚本） |
| `off` / `stop` | 关闭光标切换（停止 AHK 脚本） |
| `toggle` | 切换开关状态 |
| `status` | 查看运行状态（快捷键、PID、运行时长） |
| `restart` / `reload` | 重载配置后重启 |
| `config` / `edit` | 用记事本打开配置文件 |
| `help` | 查看帮助 |

`.cmd` 和 `.ps1` 是等效的入口。`.cmd` 不需要处理 PowerShell 执行策略，推荐日常使用。

## 配置

所有配置在 `config.ini` 中修改，无需编辑 `.ahk` 文件：

```ini
[Hotkeys]
; 快捷键规则（AHK 修饰符）：
;   ^ = Ctrl    ! = Alt    # = Win    + = Shift
; 例如：^!` = Ctrl+Alt+反引号
switch_screen=^!`

[Behavior]
; 光标移动速度：0 = 瞬间，1-100 = 带动画
move_speed=0

[General]
; 托盘图标：1 = 显示，0 = 隐藏
show_tray_icon=1
```

### 常见快捷键示例

| 想要的手势 | config.ini 写法 |
|-----------|----------------|
| Ctrl + Alt + `` ` ``（默认） | `switch_screen=^!`` ` |
| Win + `` ` `` | `switch_screen=#`` ` |
| Ctrl + Shift + Z | `switch_screen=^+z` |
| Alt + Space | `switch_screen=!Space` |
| Ctrl + Alt + → | `switch_screen=^!Right` |

修改后执行 `screen-switch.cmd restart` 即可生效。

## 开机自启

### 方法：放入启动文件夹

1. 右键 `screen-switch.cmd` → 创建快捷方式
2. `Win + R` → 输入 `shell:startup` → 回车
3. 将快捷方式移入该文件夹

启动后自动最小化运行在系统托盘，按快捷键即可工作。

## 项目结构

```
CursorScreenControl/
├── screen-switch.cmd      # CLI 入口（cmd 包装器，推荐）
├── screen-switch.ps1      # CLI 入口（PowerShell 实现）
├── screen_switch.ahk      # 核心 AHK 脚本（快捷键监听）
├── config.ini             # 用户配置（快捷键/行为）
├── run.bat                # 传统启动器（双击启动）
├── README.md
└── .gitignore
```

## 原理

1. `MonitorGet` 获取每个显示器的屏幕坐标边界
2. `MouseGetPos` 获取鼠标当前位置
3. 判断鼠标落在哪个显示器矩形内
4. 计算另一显示器矩形中心 `(Left+Right)//2, (Top+Bottom)//2`
5. `MouseMove` 移动到目标位置

## 许可

MIT
