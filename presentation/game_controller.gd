class_name GameController
extends Node
## Connects input and presentation to the model.
## All rule decisions stay in domain classes.

@export var game_config: GameConfig
@export_range(0.0, 2.0) var cast_delay_seconds: float = 0.45

## Optional composition hook for reproducible demonstrations/tests; empty uses normal randomness.
var catch_source_factory: Callable

var _session := GameSession.new()
var _run_config: GameConfig
var _busy: bool = false

@onready var _view: GameView = $GameView


func _ready() -> void:
	_view.start_requested.connect(_on_start)
	_view.cast_requested.connect(_on_cast)
	_view.return_requested.connect(_on_return)
	_view.continue_requested.connect(_on_continue)
	_view.restart_requested.connect(_on_restart)
	_view.keep_requested.connect(_on_resolve_catch.bind(true))
	_view.release_requested.connect(_on_resolve_catch.bind(false))
	_view.bind_session(_session)
	if game_config == null or not game_config.validate().is_empty():
		_view.show_error("Game configuration is unavailable. Check it and restart.")
		return
	_view.show_menu(game_config)


func get_session() -> GameSession:
	return _session


func _on_start() -> void:
	if _busy or _session.get_state() != GameSession.State.NOT_STARTED:
		return
	_start_new_game()


func _start_new_game() -> void:
	if not _session.start_new_game(game_config):
		_view.show_error("Configuration check failed:\n" + "\n".join(_session.get_start_errors()))
		return
	_run_config = game_config.duplicate(true) as GameConfig
	_start_day()


func _start_day() -> void:
	var source: CatchSource
	if catch_source_factory.is_valid():
		source = catch_source_factory.call()
	if not _session.start_day(source):
		return
	_view.show_game()
	_view.set_message("A new day on the water. Choose your catches wisely.")
	_render()


func _on_cast() -> void:
	if _busy or _session.get_state() != GameSession.State.DAY_ACTIVE:
		return
	_busy = true
	var result := _session.get_current_day().cast()
	_view.set_message("Casting...")
	_render()
	await get_tree().create_timer(cast_delay_seconds).timeout
	_busy = false
	_view.describe_catch(result, _run_config)
	if result.get_status() == CastResult.Status.CAUGHT:
		_view.show_catch_choice(_session, _run_config)
		_render()
	else:
		_finish_if_needed()


func _on_resolve_catch(keep: bool) -> void:
	if _busy or _session.get_state() != GameSession.State.DAY_ACTIVE:
		return
	if _session.get_current_day().resolve_catch(keep):
		_view.hide_catch_choice()
		_view.set_message("Added to your net." if keep else "Released. Bait is spent; the fish leaves today's sea.")
		_finish_if_needed()


func _on_return() -> void:
	if _busy or _session.get_state() != GameSession.State.DAY_ACTIVE:
		return
	if _session.get_current_day().return_to_shore():
		_finish_if_needed()


func _finish_if_needed() -> void:
	var result := _session.settle_day()
	_render()
	if result != null:
		_view.show_result(result, _session)


func _on_continue() -> void:
	if _busy or not _session.advance_day():
		return
	_start_day()


func _on_restart() -> void:
	if _busy or _session.get_state() not in [GameSession.State.DAY_SETTLED, GameSession.State.GAME_OVER, GameSession.State.VICTORY]:
		return
	_start_new_game()


func _render() -> void:
	_view.render(_session, _run_config, _busy)
