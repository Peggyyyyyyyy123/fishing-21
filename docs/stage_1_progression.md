# Stage 1：次日推进与整局胜负

本步只修改 GameSession 的整局流程，原有鱼、网兜、渔获来源、单日规则和结算算法保持不变。新增 VICTORY 状态、can_advance_day() 与 advance_day()。

## 生命周期

```text
NOT_STARTED -> start_new_game -> READY_FOR_DAY -> start_day -> DAY_ACTIVE
DAY_ACTIVE -> 主动收竿或自动结束 -> DAY_ENDED
DAY_ENDED -> settle_day -> GAME_OVER（当日不达标）
DAY_ENDED -> settle_day -> DAY_SETTLED（非最后一天通过）
DAY_ENDED -> settle_day -> VICTORY（最后一天通过）
DAY_SETTLED -> advance_day -> READY_FOR_DAY（日期加一）
GAME_OVER / VICTORY -> start_new_game -> READY_FOR_DAY（全新一局）
```

## 调用顺序

展示结果前调用 settle_day()；结果界面只有 can_advance_day() 为 true 时允许继续。点击继续先 advance_day()，成功后再 start_day()。把日期推进与当日初始化分开，使下一天提示可以插在两者之间，并避免同一次结算自动跳过结果展示。

advance_day() 只接受已结算且通过的非最后一天。成功后进入 READY_FOR_DAY，重复调用返回 false，不跳天、不重新加钱。失败、未结算、尚未开始和通关都不能继续。

推进时清空上一日引用和结算缓存，金币保留。新的一天由 start_day() 创建独立对象，鱼饵和网兜全部重置。已发出的旧日和结果引用保持其原有值，但不能参与新一天的结算。

最后一天结算通过立即进入 VICTORY，日期保留最后一天，不产生第八天。最后一天未通过则 GAME_OVER，失败判断优先。最后一天由配置船租数组长度决定，默认七天；不在流程代码硬编码 7。

金币仅累计每天通过后的盈余，任何一天不足船租都直接失败，已有存款不能补差额。失败保留历史金币便于结果展示；重开时清零。

## 完整流程验证

固定七天输入依次为：3/4/2 kg、10/11 kg、4/3/2/4/3 kg、五次空军后 7 kg、8 kg、9 kg、10 kg。覆盖主动收竿、满贯、满格和饵尽。收入依次 90/420/160/70/80/90/100，租金 40/50/60/70/80/90/100，最终金币 520。

另验证每一天失败（含第七天）、存款不能补租、存款下爆网、重复继续、不结算不能跳天、跨天旧结果隔离、胜负后重开，以及 1/2/8 天自定义曲线。

```text
Godot_console --headless --editor --path . --import
Godot_console --headless --path . --script res://tests/test_progression.gd
```

整局规则现在可以自动化跑通；尚无可玩场景和展示层，仍不符合完整可玩 Stage 1 的冻结条件。此前文档描述各步当时状态，本文件补全其后续推进能力。
