# Stage 1：开始新游戏与开始当天

本步在四个基础类上增加 GameSession 和 FishingDay。尚未实现抛竿、结算、次日推进或界面，不能据此冻结 stage-1。

## 使用顺序

```gdscript
var config := load("res://config/default_game_config.tres") as GameConfig
var session := GameSession.new()
if session.start_new_game(config):
    session.start_day()
else:
    print(session.get_start_errors())
```

start_new_game() 验证配置，复制本局配置，重置天数为 1、金币为 0，并丢弃旧的当日对象。start_day() 创建新的当日对象，读取当天船租、每日鱼饵和网兜参数。两步分离，使后续开始菜单或出海提示可以插在中间；控制器也可连续调用，不需要中间界面。

## Class Map 增量

- GameSession has-a GameConfig（本局独立副本），has-a FishingDay。
- FishingDay has-a FishingNet；不暴露可修改的网兜，只提供状态读取和渔获快照。
- 原有四个基础类和默认资源保持不变。

GameSession 管整局初始化、日期、金币和生命周期；FishingDay 管当天的鱼饵与网兜。两者都继承 RefCounted，不访问 Node、按钮、场景路径或动画。配置由调用方传入，不在领域类里加载资源或依赖全局单例。

## 状态和边界

NOT_STARTED -> start_new_game -> READY_FOR_DAY -> start_day -> DAY_ACTIVE。

只有 READY_FOR_DAY 可开始当天。未开始游戏或当天已开始时，start_day() 返回 false，且不替换已有数据。显式 start_new_game() 可重开一局；无效配置会返回 false 并保留正在运行的旧局，诊断通过 get_start_errors() 获取。

配置深复制确保编辑原资源不改变进行中的一局；后续游戏行为若需要配置，也应使用本局副本。新的一天和新的一局使用全新运行对象。下划线成员依赖 GDScript 内部成员命名约定，调用方应通过公开方法操作。

当前没有为未来胜负、结算或跳天提供空方法，也没有公开 set_day/set_coins，避免让外部任意改写流程。下一步抛竿将添加到 FishingDay，之后结算模块才能授权下一天并更新金币。

## 验证方式

```text
Godot_console --headless --editor --path . --import
Godot_console --headless --path . --script res://tests/test_foundation.gd
Godot_console --headless --path . --script res://tests/test_initialization.gd
```

新增检查覆盖初始状态、第一天、重复开始、重开时对象替换、无效配置及错误信息隔离、失败重开保留旧局、配置副本与多局隔离、自定义天数和鱼饵。尚无结算修改金币的入口，因此重开清零的检查只覆盖当前可达状态；加入结算后应补充非零金币重开的回归场景。
