extends SceneTree

var _checks: int = 0
var _failures: int = 0
var _controller: GameController
var _view: GameView


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_controller = load("res://scenes/main.tscn").instantiate() as GameController
	_controller.catalog_store = FishCatalogStore.new("res://tests/.ui_catalog.cfg")
	_controller.cast_delay_seconds = 0.001
	_controller.catch_source_factory = func() -> CatchSource: return FixedCatchSource.new([Fish.new(&"huge", 21)])
	root.add_child(_controller)
	await process_frame
	_view = _controller.get_node("GameView") as GameView
	_check(_view.get_node("%MenuOverlay").visible, "Menu visible at launch")
	_check(_button("CastButton").disabled and _button("ReturnButton").disabled, "Gameplay locked before start")
	_button("StartButton").pressed.emit()
	_button("StartButton").pressed.emit()
	var session := _controller.get_session()
	_check(session.get_day_number() == 1 and not _view.get_node("%MenuOverlay").visible, "Start button creates one first day")
	for number in range(1, 8):
		_check(not _button("CastButton").disabled, "Cast enabled for active day")
		_button("CastButton").pressed.emit()
		_button("CastButton").pressed.emit()
		_button("ReturnButton").pressed.emit()
		_check(session.get_current_day().get_bait_remaining() == 5, "Animation lock prevents duplicate cast")
		_check(_button("CastButton").disabled and _button("ReturnButton").disabled, "Both buttons locked during cast")
		await create_timer(0.03).timeout
		(_view.get_node("%KeepButton") as Button).pressed.emit()
		_check(session.get_current_day().get_total_weight_kg() == 21, "Catch reaches model and HUD")
		_check(not _button("ReturnButton").disabled, "Input restored after cast")
		_button("ReturnButton").pressed.emit()
		_check(_view.get_node("%ResultOverlay").visible, "Return opens settlement overlay")
		_check(_button("CastButton").disabled and _button("ReturnButton").disabled, "Settlement locks gameplay")
		_check(session.get_last_result().get_income() == 420, "UI settles perfect income")
		if number < 7:
			_check(_button("ContinueButton").visible, "Continue shown before final day")
			_button("ContinueButton").pressed.emit()
			_button("ContinueButton").pressed.emit()
			_check(session.get_day_number() == number + 1 and not _view.get_node("%ResultOverlay").visible, "Continue advances exactly once")
	_check(session.get_state() == GameSession.State.VICTORY, "Seven-day UI path wins")
	_check(not _button("ContinueButton").visible, "Victory hides continue")
	_check(_view.get_node("%ResultTitle").text.contains("Victory"), "Victory heading visible")
	_controller.catch_source_factory = func() -> CatchSource: return FixedCatchSource.new([Fish.new(&"big", 12), Fish.new(&"mid", 10)])
	_button("RestartButton").pressed.emit()
	_check(session.get_coins() == 0 and session.get_day_number() == 1, "Restart resets winning run")
	for index in range(2):
		_button("CastButton").pressed.emit()
		await create_timer(0.03).timeout
		(_view.get_node("%KeepButton") as Button).pressed.emit()
	_check(session.get_state() == GameSession.State.GAME_OVER and _view.get_node("%ResultOverlay").visible, "Bust automatically settles through UI")
	_check(session.get_last_result().get_income() == 0, "Bust UI shows zero income")
	_check(not _button("ContinueButton").visible, "Failure hides continue")
	_button("RestartButton").pressed.emit()
	_button("ReturnButton").pressed.emit()
	_check(session.get_state() == GameSession.State.GAME_OVER and session.get_last_result().get_income() == 0, "Empty return fails through UI")
	_controller.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/.ui_catalog.cfg"))
	print("UI: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _button(node_name: String) -> Button:
	return _view.get_node("%" + node_name) as Button


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
