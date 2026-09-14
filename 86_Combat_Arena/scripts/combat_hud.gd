extends Control
class_name CombatHUD

@onready var player_hp_bar: ProgressBar = $TopLeft/VBox/PlayerHPBar
@onready var player_hp_label: Label = $TopLeft/VBox/PlayerHPLabel
@onready var reload_bar: ProgressBar = $BottomRight/VBox/ReloadBar
@onready var reload_label: Label = $BottomRight/VBox/ReloadLabel
@onready var enemy_info_box: Control = $TopCenterHostile
@onready var enemy_hp_bar: ProgressBar = $TopCenterHostile/VBox/EnemyHPBar
@onready var enemy_hp_label: Label = $TopCenterHostile/VBox/EnemyHPLabel
@onready var reticle_normal: Control = $CenterCrosshair
@onready var reticle_scope: Control = $ScopeOverlay
@onready var damage_vignette: ColorRect = $DamageVignette
@onready var banner_box: PanelContainer = $BannerBox
@onready var banner_title: Label = $BannerBox/Margin/VBox/BannerTitle
@onready var banner_subtitle: Label = $BannerBox/Margin/VBox/BannerSubtitle
@onready var cockpit_overlay: Control = get_node_or_null("CockpitOverlay")
@onready var cockpit_visor: Control = get_node_or_null("CockpitOverlay/CockpitVisor")
@onready var critical_warning_box: Control = get_node_or_null("CriticalWarningBox")
@onready var warning_label: Label = get_node_or_null("CriticalWarningBox/WarningLabel")
@onready var alarm_audio_player: AudioStreamPlayer = get_node_or_null("AlarmAudioPlayer")
@onready var bottom_right_box: Control = get_node_or_null("BottomRight")
@onready var bottom_left_box: Control = get_node_or_null("BottomLeft")

var player_ref: CharacterBody3D = null
var enemy_ref: CharacterBody3D = null
var all_enemies: Array[CharacterBody3D] = []
var vignette_alpha: float = 0.0
var is_critical_hp: bool = false
var alarm_cooldown: float = 0.0
var strobe_phase: float = 0.0

func _ready() -> void:
	_set_mouse_filter_recursive(self)
	banner_box.visible = false
	if reticle_scope:
		reticle_scope.visible = false
	damage_vignette.modulate.a = 0.0
	if cockpit_overlay:
		cockpit_overlay.visible = true
	if reticle_normal:
		reticle_normal.visible = false # Visor HUD provides aiming reticle in cockpit mode
	if bottom_right_box:
		bottom_right_box.visible = false # Visor HUD provides ammo fan in cockpit mode
	if bottom_left_box:
		bottom_left_box.visible = false
	if critical_warning_box:
		critical_warning_box.visible = false
	if alarm_audio_player:
		alarm_audio_player.stream = ProceduralAudio.create_alarm_sound()

func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_recursive(child)

func bind_player(player: CharacterBody3D) -> void:
	player_ref = player
	if cockpit_visor:
		cockpit_visor.player_ref = player
	if not player.hp_changed.is_connected(_on_player_hp_changed):
		player.hp_changed.connect(_on_player_hp_changed)
	if not player.reload_progress.is_connected(_on_reload_progress):
		player.reload_progress.connect(_on_reload_progress)
	if not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if player.has_signal("camera_mode_changed") and not player.camera_mode_changed.is_connected(_on_camera_mode_changed):
		player.camera_mode_changed.connect(_on_camera_mode_changed)

func bind_enemy(enemy: CharacterBody3D) -> void:
	enemy_ref = enemy
	if cockpit_visor:
		cockpit_visor.enemy_ref = enemy
	if not enemy.hp_changed.is_connected(_on_enemy_hp_changed):
		enemy.hp_changed.connect(_on_enemy_hp_changed)
	if not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died)

func set_all_enemies(enemies_list: Array[CharacterBody3D]) -> void:
	all_enemies = enemies_list
	if cockpit_visor and cockpit_visor.has_method("set_all_enemies"):
		cockpit_visor.set_all_enemies(enemies_list)
	for e in all_enemies:
		if is_instance_valid(e):
			if not e.hp_changed.is_connected(_on_enemy_hp_changed):
				e.hp_changed.connect(_on_enemy_hp_changed)

func _on_camera_mode_changed(is_fps: bool) -> void:
	if cockpit_overlay:
		cockpit_overlay.visible = is_fps
	if reticle_normal:
		reticle_normal.visible = not is_fps # Show 3rd person crosshair only when out of cockpit
	if bottom_right_box:
		bottom_right_box.visible = not is_fps
	if bottom_left_box:
		bottom_left_box.visible = not is_fps

func _process(delta: float) -> void:
	# Dynamically target closest living hostile
	var closest_d: float = 999999.0
	var best_e: CharacterBody3D = null
	for e in all_enemies:
		if is_instance_valid(e) and not e.is_dead and player_ref:
			var d = player_ref.global_position.distance_to(e.global_position)
			if d < closest_d:
				closest_d = d
				best_e = e
	if best_e and best_e != enemy_ref:
		enemy_ref = best_e
		if cockpit_visor:
			cockpit_visor.enemy_ref = best_e
		_update_enemy_ui(best_e)

	# Update damage vignette fade
	if vignette_alpha > 0.0:
		vignette_alpha = maxf(0.0, vignette_alpha - delta * 2.5)
		if damage_vignette:
			damage_vignette.modulate.a = vignette_alpha

	# Critical HP alarm & pulsing strobe
	if is_critical_hp and player_ref and not player_ref.is_dead:
		strobe_phase += delta * 6.0
		var strobe_alpha = sin(strobe_phase) * 0.5 + 0.5
		if critical_warning_box:
			critical_warning_box.visible = true
			if warning_label:
				warning_label.modulate.a = 0.35 + strobe_alpha * 0.65
		alarm_cooldown -= delta
		if alarm_cooldown <= 0.0:
			alarm_cooldown = 2.8
			if alarm_audio_player:
				alarm_audio_player.play()
	elif critical_warning_box and critical_warning_box.visible:
		critical_warning_box.visible = false

	# Check for restart input
	if banner_box and banner_box.visible and Input.is_action_just_pressed("restart_game"):
		get_tree().reload_current_scene()

func _update_enemy_ui(e: CharacterBody3D) -> void:
	if not enemy_hp_bar or not enemy_hp_label:
		return
	enemy_hp_bar.max_value = e.max_hp
	enemy_hp_bar.value = e.current_hp
	enemy_hp_label.text = "HOSTILE JUGGERNAUT: %d / %d" % [int(e.current_hp), int(e.max_hp)]

func _on_player_hp_changed(cur: float, max_v: float) -> void:
	if not player_hp_bar or not player_hp_label:
		return
	player_hp_bar.max_value = max_v
	player_hp_bar.value = cur
	player_hp_label.text = "M1A4 INTEGRITY: %d / %d" % [int(cur), int(max_v)]
	vignette_alpha = 0.6
	
	is_critical_hp = (cur > 0.0 and cur / max_v <= 0.35)
	if not is_critical_hp and critical_warning_box:
		critical_warning_box.visible = false

func _on_reload_progress(ratio: float) -> void:
	if not reload_bar or not reload_label:
		return
	reload_bar.value = ratio * 100.0
	if ratio >= 0.99:
		reload_label.text = "57mm CANNON: [READY]"
		reload_label.modulate = Color(0.2, 1.0, 0.4)
	else:
		reload_label.text = "57mm CANNON: [RELOADING...]"
		reload_label.modulate = Color(1.0, 0.7, 0.2)

func _on_enemy_hp_changed(cur: float, max_v: float) -> void:
	if not enemy_hp_bar or not enemy_hp_label:
		return
	enemy_hp_bar.max_value = max_v
	enemy_hp_bar.value = cur
	enemy_hp_label.text = "HOSTILE JUGGERNAUT: %d / %d" % [int(cur), int(max_v)]

func _on_player_died() -> void:
	is_critical_hp = false
	if critical_warning_box:
		critical_warning_box.visible = false
	banner_box.visible = true
	banner_title.text = "SIGNAL LOST - UNIT DESTROYED"
	banner_title.modulate = Color(1.0, 0.2, 0.2)
	banner_subtitle.text = "PILOT KIA IN SECTOR 86\nPress [R] to Re-deploy"

func _on_enemy_died() -> void:
	pass

func show_victory_banner() -> void:
	banner_box.visible = true
	banner_title.text = "MISSION ACCOMPLISHED"
	banner_title.modulate = Color(0.3, 1.0, 0.6)
	banner_subtitle.text = "ALL HOSTILE FORCES IN SECTOR 86 NEUTRALIZED\nPress [R] to Re-deploy"
