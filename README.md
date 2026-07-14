# CursorScreenSwitch 🖥️→🖥️→🖥️

按一个快捷键，光标从当前屏幕跳到下一块屏幕的中心。支持 N 块显示器循环跳转。

## 适用场景

- 多屏用户，经常需要在不同屏幕间快速切换鼠标操作
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
.\cursor_sw.cmd on

# 或双击 run.bat（自动查找 AHK 路径）
```

启动后按 **Ctrl + Alt + `**（反引号，数字 1 左边那个键）即可跳转光标。

每按一次，光标按顺序跳到下一块屏幕的中心；末尾自动回到第一块。

## CLI 命令

```bash
cursor_sw <command>
```

`.cmd` 和 `.ps1` 等效，`.cmd` 不需要处理 PowerShell 执行策略，推荐日常使用。

| 命令 | 说明 |
|------|------|
| `on` / `start` | 启动光标切换（加载 AHK 脚本） |
| `off` / `stop` | 关闭光标切换（停止 AHK 脚本） |
| `toggle` | 切换开关状态 |
| `status` | 查看运行状态（快捷键、PID、运行时长） |
| `restart` / `reload` | 重载配置后重启 |
| `config` / `edit` | 用记事本打开配置文件 |
| `layout` | 查看显示器布局与编号 |
| `help` | 查看帮助 |

### layout 子命令

查看当前所有显示器的编号、坐标边界和分辨率：

```
cursor_sw layout
```

输出示例：

```
CursorScreenSwitch — 显示器布局
=============================================
  #1  [1920, -304 ~ 3360, 656]  1440×960
  #2  [0, 0 ~ 1920, 1080]      1920×1080  ← 主屏 (0,0)
```

这个编号是 `layout.ini` 中配置循环顺序的依据。

## 配置

有两个独立的配置文件，均无需编辑 `.ahk` 文件。

### config.ini：快捷键与行为

```ini
[Hotkeys]
; 快捷键规则（AHK 修饰符）：
;   ^ = Ctrl    ! = Alt    # = Win    + = Shift
; 例如：^!` = Ctrl+Alt+反引号
switch_screen=^!`

[General]
; 托盘图标：1 = 显示，0 = 隐藏
show_tray_icon=1
```

#### 常见快捷键示例

| 想要的手势 | config.ini 写法 |
|-----------|----------------|
| Ctrl + Alt + `` ` ``（默认） | `switch_screen=^!`` ` |
| Win + `` ` `` | `switch_screen=#`` ` |
| Ctrl + Shift + Z | `switch_screen=^+z` |
| Alt + Space | `switch_screen=!Space` |
| Ctrl + Alt + → | `switch_screen=^!Right` |

### layout.ini：跳转顺序

```ini
[MonitorCycle]
; 光标跳转循环顺序，按 MonitorGet 编号填写，用逗号分隔
; 示例: 2,1,3
; 留空则按编号自然顺序（1, 2, 3, ...）循环
order=
```

先用 `cursor_sw layout` 查看你的显示器编号，然后按喜好写进 `order=` 就行。不存在的编号会自动忽略。

修改后执行 `cursor_sw.cmd restart` 即可生效。

## 开机自启

1. 右键 `cursor_sw.cmd` → 创建快捷方式
2. `Win + R` → 输入 `shell:startup` → 回车
3. 将快捷方式移入该文件夹

## 项目结构

```
CursorScreenControl/
├── cursor_sw.cmd      # CLI 入口（cmd 包装器，推荐）
├── cursor_sw.ps1      # CLI 入口（PowerShell 实现）
├── cursor_sw.ahk      # 核心 AHK 脚本（快捷键监听）
├── config.ini         # 快捷键与行为配置
├── layout.ini         # 显示器循环顺序配置
├── run.bat            # 传统双击启动
├── README.md
└── .gitignore
```

## 原理

1. `MonitorGet` 获取所有显示器的屏幕坐标边界
2. 读取 `layout.ini` 确定跳转顺序（默认按编号自然顺序）
3. `MouseGetPos` 获取鼠标当前位置
4. 遍历顺序列表，找到光标所在的屏幕索引
5. 计算顺序列表中下一块屏幕的矩形中心 `(Left+Right)//2, (Top+Bottom)//2`
6. 使用 Windows API `SetCursorPos` 移动到目标位置

## 兼容性

- **AHK 版本**：要求 v2.x（任何次版本），v1 不兼容
- **Windows 版本**：Win 8.1+ 启用 Per-Monitor DPI Aware，Win 7 自动跳过，核心功能不受影响
- **N 屏支持**：任意数量显示器均适用，按 layout.ini 顺序循环
- **单屏场景**：检测到少于 2 块屏幕时弹提示并跳过，不会报错
- **DPI 差异**：多屏不同缩放率下坐标正常，使用 `SetCursorPos` 直调 API，避开 AHK 坐标映射层

## v1.0 手记

做这个工具的起因很简单：小羊驼说想要一个快捷键，让光标从一块屏幕跳到另一块中间。听起来就是个两小时的练手活。

结果在调试信息里发现 MonitorGet 的编号和他实际的物理布局正好相反，追下去又牵扯出 DPI 缩放、Per-Monitor Aware、SetCursorPos 和 MouseMove 的底层差异，最后干脆从双屏扩展到了 N 屏，还多了一张 layout.ini。一个快捷键的背后藏了一串 Windows 显示子系统的细节。

写代码常有这种体验——你以为是一个点，走近发现是一整条线。不是因为事情本身复杂，而是因为你每往下挖一层，都会碰到一个之前不知道存在的接口或约定。CursorScreenSwitch 就是这个过程的产物：一个从"两小时的练手活"长成"哎还挺周全"的小工具。

希望它在你手指间跑得顺畅。

> 爆米花<br>
> 2026 年 7 月 · 凌晨

## 许可

MIT
