extends SceneTree

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var controller := load("res://scenes/main.tscn").instantiate() as GameController
	var config := controller.game_config.duplicate(true) as GameConfig
	config.daily_quotas = [40, 50]
	controller.game_config = config
	root.add_child(controller)
	await process_frame
	var view := controller.get_node("GameView") as GameView
	var start := view.get_node("%StartButton") as Button
	_check(view.get_node("%MenuSubtitle").text == "FISHING 21  /  A 2-DAY VOYAGE", "Menu title follows configured run length")
	_check(start.text == "Start your 2-day voyage", "Start label follows configured run length")
	_check(view.get_node("%MenuRules").text.contains("2 days"), "Rules and start label agree")
	start.pressed.emit()
	view.get_node("%ReturnButton").pressed.emit()
	_check(controller.get_session().get_state() == GameSession.State.GAME_OVER, "Prepare real failing settlement")
	_check(view.get_node("%ResultOverlay").visible, "Result visible before error")
	config.bait_per_day = 0
	view.get_node("%RestartButton").pressed.emit()
	_check(view.get_node("%MenuOverlay").visible, "Invalid restart displays error menu")
	_check(not view.get_node("%ResultOverlay").visible, "Old result cannot cover configuration error")
	_check(start.disabled, "Invalid configuration disables start")
	_check(view.get_node("%CastButton").disabled and view.get_node("%ReturnButton").disabled, "Configuration error locks game actions")
	_check(view.get_node("%MenuRules").text.contains("Configuration check failed"), "Diagnostic is displayed")
	_check(controller.get_session().get_day_number() == 1 and controller.get_session().get_coins() == 0, "Failed restart preserves existing session")
	controller.queue_free()
	await process_frame
	# Errors can also be displayed during active gameplay; their overlay must lock it.
	controller = load("res://scenes/main.tscn").instantiate() as GameController
	root.add_child(controller)
	await process_frame
	view = controller.get_node("GameView") as GameView
	view.get_node("%StartButton").pressed.emit()
	_check(not view.get_node("%CastButton").disabled, "Active game starts unlocked")
	view.show_error("Test error")
	_check(view.get_node("%CastButton").disabled and view.get_node("%ReturnButton").disabled, "Active-game error locks background buttons")
	controller.queue_free()
	await process_frame
	print("Review: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
