class_name BedInteractable
extends Interactable

## T1 sleeping pad.
##
## Per specs/features/building_system.md §3.5 (T1 寝床) and
## specs/features/survival_balance.md §3 (warm_up + dive recovery).
## Advances the game clock by `sleep_game_hours` and warms the actor's
## body temperature. A future iteration will block sleeping during
## hostile presence; for Sprint 1 the only gate is `enabled`.

signal slept(actor: Node, advanced_game_seconds: float, warmed_amount: float)

@export var sleep_game_hours: int = 6
@export var warm_up_amount: float = 30.0
@export var clock_path: NodePath

var _clock: TimeOfDay = null


func _ready() -> void:
	if not clock_path.is_empty():
		_clock = get_node_or_null(clock_path) as TimeOfDay
	if _clock == null:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null:
			_clock = tree.root.get_node_or_null("WorldClock") as TimeOfDay


## Test seam: inject the clock without going through autoload.
func bind_clock(clock: TimeOfDay) -> void:
	_clock = clock


func _do_use(actor: Node) -> bool:
	var advanced_sec: float = float(sleep_game_hours) * 3600.0
	if _clock != null:
		_clock.advance(advanced_sec)
	var warmed: float = 0.0
	var survival: SurvivalManager = _resolve_survival(actor)
	if survival != null:
		survival.warm_up(warm_up_amount)
		warmed = warm_up_amount
	slept.emit(actor, advanced_sec, warmed)
	return true


func _resolve_survival(actor: Node) -> SurvivalManager:
	if actor == null:
		return null
	if actor.has_method("get_survival_manager"):
		var v: Variant = actor.call("get_survival_manager")
		return v as SurvivalManager
	return actor.get_node_or_null("SurvivalManager") as SurvivalManager
