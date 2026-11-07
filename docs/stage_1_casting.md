# Stage 1：抛竿与单日结束判断

新增 CatchSource 抽象契约、RandomCatchSource、CastResult，测试用 FixedCatchSource。FishingDay 新增 cast/can_cast/is_finished/get_end_reason；GameSession.start_day 可注入渔获来源，不传时使用本局配置创建随机来源。

## 职责和关系

FishingDay uses CatchSource；RandomCatchSource 和 FixedCatchSource is-a CatchSource；FishingDay has-a FishingNet；cast 返回 CastResult。随机来源只生成渔获，单日对象只消费渔获并更新一天的状态。CastResult 区分拒绝、空军、钓到鱼与来源错误，不计算金额。

这次抽象有两个真实实现：正式随机来源与可复现测试来源，服务于 DIP、LSP 与小接口原则。添加仅数值不同的鱼种仍只改配置。此前基础类和配置未修改。

## 操作契约

合法抛竿先消耗一个鱼饵，再抽鱼。null 表示空军，不入网。有效鱼强制入网；顺序判断爆网、满格、鱼饵耗尽。恰好 21 kg 不主动结束，未满格且有鱼饵时可以继续。非法操作不扣饵、不抽取；来源返回无效鱼则返回 SOURCE_ERROR 并恢复鱼饵，来源本身已抽取的状态不回滚。控制器应把来源错误作为开发错误处理。

cast 是同步规则操作，内部阻止重入；未来动画期间的按钮锁定由展示层另行负责，不能用同步模型代替动画锁。

FishingDay 一旦结束，就禁止继续抛竿。GameSession.get_state 从当前日派生 DAY_ENDED，不维护另一份可变结束标记。尚未接主动收竿、收入结算、下一天和胜负。

直接构造 FishingDay 不传来源时，可读取初始状态但无法抛竿；正式调用使用 GameSession.start_day 自动连接来源。RandomCatchSource 的构造前提是已验证配置；公开游戏入口 start_new_game 会验证。

## 随机与验证

按概率累计区间抽结果，区间左闭右开；鱼种内部用 randi_range 抽整数。处理 randf 可能返回 1 的边界，并对校验容差内的概率和归一化。来源复制鱼种配置，随机数生成器支持固定种子。

```text
Godot_console --headless --editor --path . --import
Godot_console --headless --path . --script res://tests/test_casting.gd
```

测试用固定渔获重现空军、满贯后继续、爆网、满格、饵尽及优先级，检查拒绝操作不变更数据、来源错误、结果隔离、概率边界、固定种子复现及重量区间。10000 次固定种子抽取只做宽容差频率检查，不验证策划表中的策略通过率。
