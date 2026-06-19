# 运行手册

## 运行游戏

1. 安装 Godot 4.x。
2. 用 Godot 打开本仓库根目录。
3. 运行主场景 `res://scenes/main.tscn`。

## 操作

- `WASD` 或方向键：移动拟人化边牧。
- 自动攻击：边牧会从手部周期性发射追踪攻击球。
- `R`：胜利或失败后重新开始。

## 目标

在倒计时结束前存活。牛羊是敌人，会追踪玩家并在接触时造成伤害。

## 验证

如果 `godot` 已加入 PATH，可运行：

```powershell
godot --headless --script scripts/test_runner.gd
```

如果当前 shell 无法解析 `godot`，可使用本机已知 Godot console exe 路径运行：

```powershell
& 'C:\Users\Crimson\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe' --headless --script scripts/test_runner.gd
```

期望输出包含：

```text
TESTS PASSED
```

主场景 headless smoke 可运行：

```powershell
& 'C:\Users\Crimson\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe' --headless --path . --scene res://scenes/main.tscn --quit-after 2
```

期望命令退出码为 0。

## 验收记录

2026-06-19：

- 自动化测试：运行 `& 'C:\Users\Crimson\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe' --headless --script scripts/test_runner.gd`，结果通过，输出包含 `TESTS PASSED`。
- 主场景 headless smoke：运行 `& 'C:\Users\Crimson\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe' --headless --path . --scene res://scenes/main.tscn --quit-after 2`，结果通过，退出码为 0。
- 可见/手动游玩：非交互式 agent 环境未执行可见窗口手动游玩验收。

## 调试辅助层

正常运行默认不显示碰撞、范围、坐标、刷怪区或对象池信息。后续如需加入调试辅助层，必须通过显式调试参数或专用验证入口开启。
