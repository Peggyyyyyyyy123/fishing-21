# Stage 1：主动收竿与每日结算

新增 SettlementRules 和 DayResult。FishingDay 增加 return_to_shore() 和 RETURNED 原因；GameSession 增加 settle_day()/get_last_result()、DAY_SETTLED 与 GAME_OVER 状态。

## 责任与使用

FishingDay 只负责停止当天，不计算钱。SettlementRules 只读已结束当天的数据，计算 DayResult，不修改鱼饵、网兜或金币。GameSession 持有本局结算规则，负责把净收益计入金币且只计入一次。DayResult 是结果快照，包含天数、结束原因、总重、鱼数、收入、船租、满贯标记和派生结果。

```gdscript
var day := session.get_current_day()
day.return_to_shore() # 主动结束；自动结束时无需调用
var result := session.settle_day()
if result != null:
    print(result.get_income(), result.get_quota(), result.get_net_income())
```

抛竿自动结束后，展示/控制层同样调用 settle_day()。此步尚无界面，未用动画回调触发结算。游戏核心仍与场景树分离。

## 规则和边界

- 普通收入 = 总重 x 单价；严格等于承重上限且未爆网时再乘满贯倍率。
- 爆网收入按配置，默认 0；爆网不能通过收竿改写结束原因。
- 空网允许收竿，收竿不消耗鱼饵；结束后不能再收竿或抛竿。
- 收入 >= 当日船租才通过。get_net_income() 为收入减船租，可为负数以展示缺口；get_coin_gain() 仅在通过时返回净收益，失败为 0，不扣累计金币补租。
- 尚未结束不能结算。重复结算返回独立快照，不重复计钱；读取或修改外部结果不改变已保存结果。重新开始清除金币和旧结果。
- 通过后处于 DAY_SETTLED，失败立即 GAME_OVER。结算时不增加天数，保留当天信息供展示。下一步再加入“继续下一天”和第七天胜利；本步尚无法完成七天整局，不可冻结 stage-1。

SRP：收竿、计算和金币入账分别属于不同类。领域对象通过参数组合，计价规则暂只有一种实现，不添加无用接口。规则构造值来自本局独立配置，外部编辑资源不影响进行中的结算。

## 验证

```text
Godot_console --headless --editor --path . --import
Godot_console --headless --path . --script res://tests/test_settlement.gd
```

覆盖普通、满贯、爆网、空网、饵尽、满格、精确达标、收竿重入保护、重复结算、结果快照隔离、非零金币重开、无效阶段结算以及自定义计价参数。累计金币不能补后续船租的跨天场景将在下一天推进实现后补测。
