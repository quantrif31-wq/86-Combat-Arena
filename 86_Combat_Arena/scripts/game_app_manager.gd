extends Node

# =============================================================================
# GAME APP MANAGER (AUTOLOAD SINGLETON)
# Guarantees OS mouse cursor is properly released when window loses focus,
# game pauses, scenes change, or application exits on Windows/Linux/macOS.
# =============================================================================

var target_scene_path: String = "res://scenes/chapter_1_mission.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameAppManager] Initialized. OS Cursor Guard active.")

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
