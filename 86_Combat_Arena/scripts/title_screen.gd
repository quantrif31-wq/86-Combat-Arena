extends Control
class_name TitleScreen

# Audio streams
const TITLE_BGM = preload("res://assets/audio/title_ambient_theme.wav")
const SFX_HOVER = preload("res://assets/audio/ui_hover.wav")
const SFX_CLICK = preload("res://assets/audio/ui_click.wav")
const SFX_SYNC = preload("res://assets/audio/pararaid_sync.wav")

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var sfx_hover_player: AudioStreamPlayer = $SFXHoverPlayer

# UI Nodes
@onready var btn_chapter: Button = $LeftPanel/VBox/BtnChapter
@onready var btn_sortie: Button = $LeftPanel/VBox/BtnSortie
@onready var btn_briefing: Button = $LeftPanel/VBox/BtnBriefing
@onready var btn_archive: Button = $LeftPanel/VBox/BtnArchive
@onready var btn_audio: Button = $LeftPanel/VBox/BtnAudio
@onready var btn_exit: Button = $LeftPanel/VBox/BtnExit

@onready var modal_overlay: ColorRect = $ModalOverlay
@onready var modal_briefing: PanelContainer = $ModalOverlay/ModalBriefing
@onready var modal_archive: PanelContainer = $ModalOverlay/ModalArchive
@onready var modal_pilot_selection: Control = get_node_or_null("ModalOverlay/PilotSelectionModal")
@onready var btn_close_briefing: Button = $ModalOverlay/ModalBriefing/VBox/BtnCloseBriefing
@onready var btn_close_archive: Button = $ModalOverlay/ModalArchive/VBox/BtnCloseArchive

@onready var fade_curtain: ColorRect = $FadeCurtain

var is_transitioning: bool = false
var audio_muted: bool = false
var pending_sortie_target: String = "res://scenes/chapter_1_mission.tscn"

func _ready() -> void:
	# Ensure mouse mode is visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Setup audio players
	if bgm_player:
		bgm_player.stream = TITLE_BGM
		bgm_player.volume_db = -6.0
		bgm_player.play()
		
	# Setup modal overlay
	modal_overlay.visible = false
	modal_briefing.visible = false
	modal_archive.visible = false
	if modal_pilot_selection:
		modal_pilot_selection.visible = false
		modal_pilot_selection.sortie_confirmed.connect(_on_pilot_sortie_confirmed)
		modal_pilot_selection.modal_closed.connect(_on_close_modal_pressed)
	
	# Fade in from black
	fade_curtain.visible = true
	fade_curtain.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_curtain, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Connect buttons
	_connect_button(btn_chapter, _on_chapter_pressed)
	_connect_button(btn_sortie, _on_sortie_pressed)
	_connect_button(btn_briefing, _on_briefing_pressed)
	_connect_button(btn_archive, _on_archive_pressed)
	_connect_button(btn_audio, _on_audio_toggle_pressed)
	_connect_button(btn_exit, _on_exit_pressed)
	
	_connect_button(btn_close_briefing, _on_close_modal_pressed)
	_connect_button(btn_close_archive, _on_close_modal_pressed)

func _connect_button(btn: Button, callback: Callable) -> void:
	if btn:
		btn.mouse_entered.connect(_on_button_hovered)
		btn.pressed.connect(callback)

func _on_button_hovered() -> void:
	if not is_transitioning and sfx_hover_player:
		sfx_hover_player.stream = SFX_HOVER
		sfx_hover_player.volume_db = -10.0
		sfx_hover_player.pitch_scale = randf_range(0.96, 1.04)
		sfx_hover_player.play()

func _play_click() -> void:
	if sfx_player:
		sfx_player.stream = SFX_CLICK
		sfx_player.volume_db = -4.0
		sfx_player.play()

func _on_chapter_pressed() -> void:
	pending_sortie_target = "res://scenes/chapter_1_mission.tscn"
	_open_pilot_selection()

func _on_sortie_pressed() -> void:
	pending_sortie_target = "res://scenes/main_arena.tscn"
	_open_pilot_selection()

func _open_pilot_selection() -> void:
	if is_transitioning:
		return
	_play_click()
	modal_overlay.visible = true
	modal_briefing.visible = false
	modal_archive.visible = false
	if modal_pilot_selection:
		modal_pilot_selection.visible = true

func _on_pilot_sortie_confirmed(pilot_id: String) -> void:
	if GameAppManager:
		GameAppManager.selected_pilot = pilot_id
		GameAppManager.target_scene_path = pending_sortie_target
	_start_transition_to_loading()

func _start_transition_to_loading() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_play_click()
	
	# Play Para-RAID sync sound for deployment
	if sfx_player:
		sfx_player.stream = SFX_SYNC
		sfx_player.volume_db = -2.0
		sfx_player.play()
		
	# Fade BGM out and transition to loading screen
	var tween = create_tween().set_parallel(true)
	tween.tween_property(bgm_player, "volume_db", -36.0, 1.2)
	tween.tween_property(fade_curtain, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_briefing_pressed() -> void:
	if is_transitioning:
		return
	_play_click()
	modal_overlay.visible = true
	modal_briefing.visible = true
	modal_archive.visible = false
	if modal_pilot_selection:
		modal_pilot_selection.visible = false

func _on_archive_pressed() -> void:
	if is_transitioning:
		return
	_play_click()
	modal_overlay.visible = true
	modal_briefing.visible = false
	modal_archive.visible = true
	if modal_pilot_selection:
		modal_pilot_selection.visible = false

func _on_close_modal_pressed() -> void:
	_play_click()
	modal_overlay.visible = false
	modal_briefing.visible = false
	modal_archive.visible = false
	if modal_pilot_selection:
		modal_pilot_selection.visible = false

func _on_audio_toggle_pressed() -> void:
	_play_click()
	audio_muted = not audio_muted
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, audio_muted)
	if btn_audio:
		btn_audio.text = "[ 04 // AUDIO: MUTED ]" if audio_muted else "[ 04 // AUDIO: ACTIVE ]"

func _on_exit_pressed() -> void:
	_play_click()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	get_tree().quit()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if modal_overlay.visible:
			_on_close_modal_pressed()
