extends Control
class_name PilotSelectionModal

signal pilot_selected(pilot_id: String)
signal sortie_confirmed(pilot_id: String)
signal modal_closed()

const SFX_HOVER = preload("res://assets/audio/ui_hover.wav")
const SFX_CLICK = preload("res://assets/audio/ui_click.wav")
const SFX_SYNC = preload("res://assets/audio/pararaid_sync.wav")

var current_pilot: String = "undertaker"
var sfx_player: AudioStreamPlayer = null
var sfx_hover_player: AudioStreamPlayer = null

@onready var btn_card_undertaker: Button = $VBox/CardsContainer/CardUndertaker/BtnSelect
@onready var btn_card_wehrwolf: Button = $VBox/CardsContainer/CardWehrwolf/BtnSelect
@onready var btn_card_gunslinger: Button = $VBox/CardsContainer/CardGunslinger/BtnSelect

@onready var card_undertaker: PanelContainer = $VBox/CardsContainer/CardUndertaker
@onready var card_wehrwolf: PanelContainer = $VBox/CardsContainer/CardWehrwolf
@onready var card_gunslinger: PanelContainer = $VBox/CardsContainer/CardGunslinger

@onready var btn_confirm: Button = $VBox/BottomActions/BtnConfirmSortie
@onready var btn_cancel: Button = $VBox/BottomActions/BtnCancel
@onready var lbl_selected_info: Label = $VBox/SelectedInfoPanel/Margin/LblInfo

func _ready() -> void:
	# Audio setup
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
	sfx_hover_player = AudioStreamPlayer.new()
	sfx_hover_player.bus = "Master"
	add_child(sfx_hover_player)
	
	# Connect cards
	_setup_card_button(btn_card_undertaker, "undertaker")
	_setup_card_button(btn_card_wehrwolf, "wehrwolf")
	_setup_card_button(btn_card_gunslinger, "gunslinger")
	
	if btn_confirm:
		btn_confirm.pressed.connect(_on_confirm_pressed)
		btn_confirm.mouse_entered.connect(_play_hover)
	if btn_cancel:
		btn_cancel.pressed.connect(_on_cancel_pressed)
		btn_cancel.mouse_entered.connect(_play_hover)
		
	# Select default
	var gam = get_node_or_null("/root/GameAppManager")
	if gam:
		current_pilot = gam.selected_pilot
	select_pilot(current_pilot)

func _setup_card_button(btn: Button, pilot_id: String) -> void:
	if btn:
		btn.pressed.connect(func(): select_pilot(pilot_id))
		btn.mouse_entered.connect(_play_hover)

func _play_hover() -> void:
	if sfx_hover_player:
		sfx_hover_player.stream = SFX_HOVER
		sfx_hover_player.volume_db = -12.0
		sfx_hover_player.pitch_scale = randf_range(0.95, 1.05)
		sfx_hover_player.play()

func _play_click() -> void:
	if sfx_player:
		sfx_player.stream = SFX_CLICK
		sfx_player.volume_db = -4.0
		sfx_player.play()

func select_pilot(pilot_id: String) -> void:
	current_pilot = pilot_id
	var gam = get_node_or_null("/root/GameAppManager")
	if gam:
		gam.selected_pilot = pilot_id
	_play_click()
	
	_update_card_styles()
	_update_info_label()
	pilot_selected.emit(pilot_id)

func _update_card_styles() -> void:
	var cards = {
		"undertaker": card_undertaker,
		"wehrwolf": card_wehrwolf,
		"gunslinger": card_gunslinger
	}
	
	for id in cards:
		var card = cards[id]
		if not card:
			continue
		var is_selected = (id == current_pilot)
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.border_width_left = 3 if is_selected else 1
		style.border_width_right = 3 if is_selected else 1
		style.border_width_top = 3 if is_selected else 1
		style.border_width_bottom = 3 if is_selected else 1
		
		if is_selected:
			match id:
				"undertaker":
					style.bg_color = Color(0.18, 0.04, 0.05, 0.95)
					style.border_color = Color(1.0, 0.25, 0.25, 1.0)
				"wehrwolf":
					style.bg_color = Color(0.16, 0.12, 0.04, 0.95)
					style.border_color = Color(1.0, 0.7, 0.2, 1.0)
				"gunslinger":
					style.bg_color = Color(0.04, 0.14, 0.18, 0.95)
					style.border_color = Color(0.2, 0.8, 1.0, 1.0)
		else:
			style.bg_color = Color(0.07, 0.08, 0.10, 0.85)
			style.border_color = Color(0.3, 0.35, 0.4, 0.5)
			
		card.add_theme_stylebox_override("panel", style)
		
		# Update card selection tag
		var tag = card.find_child("LblSelectStatus", true, false) as Label
		if tag:
			tag.text = "▶ [ SELECTED UNIT ] ◀" if is_selected else "[ CLICK TO SELECT ]"
			tag.modulate = Color(1.0, 0.9, 0.3) if is_selected else Color(0.6, 0.6, 0.6)

func _update_info_label() -> void:
	var gam = get_node_or_null("/root/GameAppManager")
	if not lbl_selected_info or not gam:
		return
	var config = gam.get_pilot_config(current_pilot)
	lbl_selected_info.text = "HÓA THÂN: " + config.pilot_name + " [" + config.callsign + "] — " + config.role + "\n" + config.special_desc

func _on_confirm_pressed() -> void:
	if sfx_player:
		sfx_player.stream = SFX_SYNC
		sfx_player.volume_db = -2.0
		sfx_player.play()
	sortie_confirmed.emit(current_pilot)

func _on_cancel_pressed() -> void:
	_play_click()
	modal_closed.emit()
