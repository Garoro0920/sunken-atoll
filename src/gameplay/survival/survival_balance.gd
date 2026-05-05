class_name SurvivalBalance
extends Resource

## Designer-tunable balance values for the survival system.
##
## Per specs/features/survival_balance.md §3.2 / §3.3.
## Saved as .tres so designers can adjust without touching code or
## requiring a rebuild. SurvivalManager loads one of these on init.

# --- Decay rates (per game-minute) ---
@export_group("Decay rates per game-minute")
@export var hunger_decay_per_min: float = 0.5
@export var thirst_decay_per_min: float = 1.0
@export var oxygen_decay_per_min_when_diving: float = 10.0
@export var contamination_recovery_per_min: float = 0.2

# --- Body temperature deltas per game-minute by environment ---
@export_group("Body-temp delta per game-minute")
@export var body_temp_delta_night: float = -1.0
@export var body_temp_delta_rain: float = -1.5
@export var body_temp_delta_storm: float = -3.0
@export var body_temp_delta_clear_day: float = 0.5  # gentle recovery
@export var body_temp_delta_fire_radius_m: float = 5.0  # used by SurvivalManager

# --- Thresholds (per spec §3.3 derived effects table) ---
@export_group("Thresholds")
@export var hp_min: float = 0.0
@export var hp_max: float = 100.0
@export var hunger_min: float = 0.0
@export var hunger_max: float = 100.0
@export var hunger_lethal_threshold: float = 10.0
@export var thirst_min: float = 0.0
@export var thirst_max: float = 100.0
@export var thirst_lethal_threshold: float = 10.0
@export var body_temp_min: float = -100.0
@export var body_temp_max: float = 100.0
@export var body_temp_cold_threshold: float = -40.0
@export var body_temp_hot_threshold: float = 40.0
@export var body_temp_lethal_abs: float = 70.0
@export var oxygen_min: float = 0.0
@export var oxygen_max: float = 100.0
@export var oxygen_critical_threshold: float = 20.0  # vignette starts here
@export var contamination_min: float = 0.0
@export var contamination_max: float = 100.0
@export var contamination_warn_threshold: float = 50.0
@export var contamination_lethal_threshold: float = 70.0

# --- Damage rates when in lethal zones (per game-minute) ---
@export_group("HP damage from sub-systems (per game-minute)")
@export var hp_damage_when_starving: float = 1.0
@export var hp_damage_when_dehydrated: float = 1.5
@export var hp_damage_when_extreme_temp: float = 0.8
@export var hp_damage_when_oxygen_zero: float = 30.0  # rapid drown
@export var hp_damage_when_contaminated: float = 0.6

# --- Movement/perf modifiers (consumed by other systems via signal) ---
@export_group("Derived modifiers")
@export var move_speed_multiplier_when_hungry: float = 0.9  # at < 30 hunger
@export var stamina_recovery_multiplier_when_thirsty: float = 0.5  # at < 30 thirst
@export var stamina_max_multiplier_when_contaminated: float = 0.8  # at > 50
