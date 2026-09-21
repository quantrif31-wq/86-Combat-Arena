extends Node

# =============================================================================
# GAME APP MANAGER (AUTOLOAD SINGLETON)
# Guarantees OS mouse cursor is properly released when window loses focus,
# game pauses, scenes change, or application exits on Windows/Linux/macOS.
# =============================================================================

var target_scene_path: String = "res://scenes/chapter_1_mission.tscn"
var selected_pilot: String = "undertaker" # "undertaker", "wehrwolf", "gunslinger"

const PILOT_CONFIGS = {
	"undertaker": {
		"id": "undertaker",
		"callsign": "UNDERTAKER",
		"pilot_name": "Shin Nouzen",
		"rank": "Spearhead Squadron Captain",
		"model_path": "res://assets/models/m1a4_undertaker.glb",
		"max_hp": 110.0,
		"speed": 8.8,
		"cannon_damage": 60.0,
		"fire_cooldown": 1.9,
		"zoom_levels": [1.0, 1.8, 2.5],
		"role": "Close-Quarter Ace & Vanguard",
		"special_desc": "Song kiếm cao tần (Dual HF Blades) + Cảm nhận giọng nói Legion qua Para-RAID + Tốc độ phản xạ cực cao.",
		"emblem_desc": "Kỵ sĩ không đầu (Headless Skeleton)",
		"armor_stat": 75,
		"speed_stat": 95,
		"firepower_stat": 85,
		"range_stat": 70
	},
	"wehrwolf": {
		"id": "wehrwolf",
		"callsign": "WEHRWOLF",
		"pilot_name": "Raiden Shuga",
		"rank": "Spearhead Vice-Captain",
		"model_path": "res://assets/models/m1a4_wehrwolf.glb",
		"max_hp": 150.0,
		"speed": 7.2,
		"cannon_damage": 65.0,
		"fire_cooldown": 2.2,
		"zoom_levels": [1.0, 1.6, 2.2],
		"role": "Heavy Point Defender & Tank",
		"special_desc": "Giáp hông gia cường (Reinforced Hip Armor) + Cặp pháo tự động 12.7mm thứ cấp + Khả năng trụ phòng ngự tối đa.",
		"emblem_desc": "Ma sói thép (Iron Werewolf)",
		"armor_stat": 95,
		"speed_stat": 70,
		"firepower_stat": 88,
		"range_stat": 75
	},
	"gunslinger": {
		"id": "gunslinger",
		"callsign": "GUNSLINGER",
		"pilot_name": "Kurena Kukumila",
		"rank": "Spearhead Long-Range Marksman",
		"model_path": "res://assets/models/m1a4_gunslinger.glb",
		"max_hp": 90.0,
		"speed": 8.0,
		"cannon_damage": 105.0,
		"fire_cooldown": 3.0,
		"zoom_levels": [1.0, 3.0, 6.0, 12.0],
		"role": "Long-Range Sniper Specialist",
		"special_desc": "Nòng pháo 57mm kéo dài với loa che lửa 4 khoang + Kính ngắm quang học chuyên dụng zoom 3 tầng (3x/6x/12x) + Đạn APFSDS siêu vận tốc.",
		"emblem_desc": "Linh miêu xạ thủ (Gunslinger Lynx)",
		"armor_stat": 60,
		"speed_stat": 82,
		"firepower_stat": 98,
		"range_stat": 100
	}
}

static func get_pilot_config(pilot_id: String) -> Dictionary:
	if PILOT_CONFIGS.has(pilot_id):
		return PILOT_CONFIGS[pilot_id]
	return PILOT_CONFIGS["undertaker"]

func get_current_pilot_config() -> Dictionary:
	return get_pilot_config(selected_pilot)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameAppManager] Initialized. OS Cursor Guard active. Selected Pilot: ", selected_pilot)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			# Window lost focus: Immediately unlock cursor so user can use other apps/monitors
			release_mouse()
		NOTIFICATION_WM_CLOSE_REQUEST:
			# Window close requested: release cursor before quitting
			release_mouse()
		NOTIFICATION_PREDELETE:
			# Engine teardown
			release_mouse()

static func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)

static func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
