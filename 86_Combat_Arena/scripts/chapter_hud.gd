extends CombatHUD
class_name ChapterHUD

# =============================================================================
# CHAPTER HUD: EXPANDED HUD FOR 86 CAMPAIGN MISSION
# Base Integrity, Squad Status, Timeline Clock, Para-RAID Radio Comms, Boss Bar
# =============================================================================

signal proceed_to_phase_2_requested()

# Campaign Specific Controls
var base_hp_bar: ProgressBar = null
var base_hp_label: Label = null
var timeline_badge: Label = null
var legion_counter_label: Label = null

var ally_wehrwolf_label: Label = null
var ally_gunslinger_label: Label = null

# Para-RAID Dialogue Box
var pararaid_box: PanelContainer = null
var pararaid_speaker: Label = null
var pararaid_msg: Label = null
var pararaid_timer: float = 0.0

# Boss Bar (Shepherd)
var boss_bar_panel: PanelContainer = null
var boss_hp_bar: ProgressBar = null
var boss_title_label: Label = null

# Intermission Time-Skip Modal
var intermission_modal: ColorRect = null
var intermission_log_label: Label = null
var btn_proceed_phase2: Button = null

func _ready() -> void:
	super._ready()
	_create_campaign_ui_elements()

func _create_campaign_ui_elements() -> void:
	# 1. Timeline & Base Integrity (Top Center / Left)
	var top_campaign_box = VBoxContainer.new()
	top_campaign_box.name = "TopCampaignBox"
	top_campaign_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_campaign_box.position = Vector2(30, 80)
	top_campaign_box.custom_minimum_size = Vector2(320, 110)
	top_campaign_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_campaign_box)
	
	# Timeline Clock Badge
	timeline_badge = Label.new()
	timeline_badge.text = "[ TIMELINE: 12:45 // HIGH NOON ASSAULT ]"
	timeline_badge.modulate = Color(1.0, 0.85, 0.3)
	timeline_badge.add_theme_font_size_override("font_size", 13)
	top_campaign_box.add_child(timeline_badge)
	
	# Base Integrity
	var base_box = HBoxContainer.new()
	base_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_campaign_box.add_child(base_box)
	
	var base_title = Label.new()
	base_title.text = "FORWARD BASE:"
	base_title.add_theme_font_size_override("font_size", 12)
	base_title.modulate = Color(0.4, 0.9, 1.0)
	base_box.add_child(base_title)
	
	base_hp_label = Label.new()
	base_hp_label.text = " 100%"
	base_hp_label.add_theme_font_size_override("font_size", 12)
	base_hp_label.modulate = Color(0.4, 1.0, 0.5)
	base_box.add_child(base_hp_label)
	
	base_hp_bar = ProgressBar.new()
	base_hp_bar.max_value = 1000.0
	base_hp_bar.value = 1000.0
	base_hp_bar.show_percentage = false
	base_hp_bar.custom_minimum_size = Vector2(310, 8)
	base_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bg_sb = StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	bg_sb.set_border_width_all(1)
	bg_sb.border_color = Color(0.2, 0.5, 0.7, 0.5)
	base_hp_bar.add_theme_stylebox_override("background", bg_sb)
	
	var fg_sb = StyleBoxFlat.new()
	fg_sb.bg_color = Color(0.2, 0.85, 0.5, 0.9)
	base_hp_bar.add_theme_stylebox_override("fill", fg_sb)
	top_campaign_box.add_child(base_hp_bar)
	
	# Squad Status
	var squad_title = Label.new()
	squad_title.text = "SPEARHEAD SQUADRON:"
	squad_title.add_theme_font_size_override("font_size", 11)
	squad_title.modulate = Color(0.7, 0.8, 0.9)
	top_campaign_box.add_child(squad_title)
	
	ally_wehrwolf_label = Label.new()
	ally_wehrwolf_label.text = " • [02] WEHRWOLF (RAIDEN): 140 / 140"
	ally_wehrwolf_label.add_theme_font_size_override("font_size", 11)
	ally_wehrwolf_label.modulate = Color(0.3, 0.85, 1.0)
	top_campaign_box.add_child(ally_wehrwolf_label)
	
	ally_gunslinger_label = Label.new()
	ally_gunslinger_label.text = " • [03] GUNSLINGER (KURENA): 100 / 100"
	ally_gunslinger_label.add_theme_font_size_override("font_size", 11)
	ally_gunslinger_label.modulate = Color(0.3, 0.85, 1.0)
	top_campaign_box.add_child(ally_gunslinger_label)
	
	# Legion Threats Counter
	legion_counter_label = Label.new()
	legion_counter_label.text = "HOSTILE LEGION: 0 REMAINING"
	legion_counter_label.add_theme_font_size_override("font_size", 12)
	legion_counter_label.modulate = Color(1.0, 0.3, 0.3)
	top_campaign_box.add_child(legion_counter_label)

	# 2. Boss Health Bar (Top Center)
	boss_bar_panel = PanelContainer.new()
	boss_bar_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar_panel.position = Vector2(400, 30)
	boss_bar_panel.custom_minimum_size = Vector2(480, 50)
	boss_bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar_panel.visible = false
	add_child(boss_bar_panel)
	
	var boss_vbox = VBoxContainer.new()
	boss_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar_panel.add_child(boss_vbox)
	
	boss_title_label = Label.new()
	boss_title_label.text = "[ LEGION COMMANDER // SHEPHERD: THE NAMELESS REAPER ]"
	boss_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_title_label.add_theme_font_size_override("font_size", 13)
	boss_title_label.modulate = Color(1.0, 0.15, 0.15)
	boss_vbox.add_child(boss_title_label)
	
	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.max_value = 450.0
	boss_hp_bar.value = 450.0
	boss_hp_bar.show_percentage = false
	boss_hp_bar.custom_minimum_size = Vector2(470, 10)
	boss_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var b_fg = StyleBoxFlat.new()
	b_fg.bg_color = Color(0.95, 0.1, 0.15, 0.95)
	boss_hp_bar.add_theme_stylebox_override("fill", b_fg)
	boss_vbox.add_child(boss_hp_bar)

	# 3. Para-RAID Dialogue Box (Bottom Left-Center)
	pararaid_box = PanelContainer.new()
	pararaid_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pararaid_box.position = Vector2(40, 530)
	pararaid_box.custom_minimum_size = Vector2(520, 95)
	pararaid_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pararaid_box.visible = false
	
	var p_panel_style = StyleBoxFlat.new()
	p_panel_style.bg_color = Color(0.04, 0.06, 0.09, 0.88)
	p_panel_style.set_border_width_all(1)
	p_panel_style.border_color = Color(0.2, 0.7, 0.9, 0.6)
	p_panel_style.corner_radius_top_left = 4
	p_panel_style.corner_radius_top_right = 4
	p_panel_style.corner_radius_bottom_right = 4
	p_panel_style.corner_radius_bottom_left = 4
	pararaid_box.add_theme_stylebox_override("panel", p_panel_style)
	add_child(pararaid_box)
	
	var p_margin = MarginContainer.new()
	p_margin.add_theme_constant_override("margin_left", 12)
	p_margin.add_theme_constant_override("margin_right", 12)
	p_margin.add_theme_constant_override("margin_top", 8)
	p_margin.add_theme_constant_override("margin_bottom", 8)
	p_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pararaid_box.add_child(p_margin)
	
	var p_vbox = VBoxContainer.new()
	p_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p_margin.add_child(p_vbox)
	
	pararaid_speaker = Label.new()
	pararaid_speaker.text = "// PARA-RAID: HANDLER ONE (LENA)"
	pararaid_speaker.add_theme_font_size_override("font_size", 12)
	pararaid_speaker.modulate = Color(0.3, 0.85, 1.0)
	p_vbox.add_child(pararaid_speaker)
	
	pararaid_msg = Label.new()
	pararaid_msg.text = "Undertaker, multiple hostile Legion units entering the grid!"
	pararaid_msg.add_theme_font_size_override("font_size", 13)
	pararaid_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pararaid_msg.modulate = Color(0.95, 0.98, 1.0)
	p_vbox.add_child(pararaid_msg)

	# 4. Intermission Time-Skip Modal (Phase 1 -> Phase 2)
	intermission_modal = ColorRect.new()
	intermission_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	intermission_modal.color = Color(0.02, 0.03, 0.05, 0.94)
	intermission_modal.visible = false
	intermission_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(intermission_modal)
	
	var inter_center = CenterContainer.new()
	inter_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	intermission_modal.add_child(inter_center)
	
	var inter_card = PanelContainer.new()
	inter_card.custom_minimum_size = Vector2(650, 360)
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	card_sb.set_border_width_all(2)
	card_sb.border_color = Color(0.85, 0.25, 0.25, 0.8)
	card_sb.corner_radius_top_left = 6
	card_sb.corner_radius_top_right = 6
	card_sb.corner_radius_bottom_right = 6
	card_sb.corner_radius_bottom_left = 6
	inter_card.add_theme_stylebox_override("panel", card_sb)
	inter_center.add_child(inter_card)
	
	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 30)
	card_margin.add_theme_constant_override("margin_right", 30)
	card_margin.add_theme_constant_override("margin_top", 25)
	card_margin.add_theme_constant_override("margin_bottom", 25)
	inter_card.add_child(card_margin)
	
	var card_vbox = VBoxContainer.new()
	card_margin.add_child(card_vbox)
	
	var inter_hdr = Label.new()
	inter_hdr.text = "// SECTOR 86 - COMBAT LOG // PHASE 1 COMPLETED"
	inter_hdr.add_theme_font_size_override("font_size", 16)
	inter_hdr.modulate = Color(0.9, 0.3, 0.3)
	card_vbox.add_child(inter_hdr)
	
	var time_trans = Label.new()
	time_trans.text = "TIMELINE TRANSITION: 13:10  ──►  23:30 [NIGHT FALL]"
	time_trans.add_theme_font_size_override("font_size", 14)
	time_trans.modulate = Color(1.0, 0.85, 0.3)
	card_vbox.add_child(time_trans)
	
	var sep = HSeparator.new()
	card_vbox.add_child(sep)
	
	intermission_log_label = Label.new()
	intermission_log_label.text = "\nĐợt tấn công trinh sát giữa trưa của Legion đã bị bẻ gãy.\nCăn cứ tiền phương Spearhead tạm thời giữ vững được phòng tuyến.\n\nNhưng khi hoàng hôn buông xuống, Shin (Undertaker) nghe thấy những âm thanh quen thuộc vang lên trong đầu qua liên kết Para-RAID... Hàng trăm tiếng than khóc và rên rỉ của những linh hồn tử trận.\n\nCuộc đại tập kích ban đêm của bầy Legion đã bắt đầu, dẫn đầu bởi 'Shepherd' - Con Đầu Đàn mang não bộ của chỉ huy tử trận. Không được để chúng tiến vào ngôi làng phía sau!\n"
	intermission_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intermission_log_label.add_theme_font_size_override("font_size", 13)
	intermission_log_label.modulate = Color(0.9, 0.95, 1.0)
	card_vbox.add_child(intermission_log_label)
	
	btn_proceed_phase2 = Button.new()
	btn_proceed_phase2.text = "[ SORTIE INTO THE MIDNIGHT SIEGE ]"
	btn_proceed_phase2.custom_minimum_size = Vector2(280, 42)
	btn_proceed_phase2.pressed.connect(_on_proceed_pressed)
	card_vbox.add_child(btn_proceed_phase2)

func _process(delta: float) -> void:
	super._process(delta)
	if pararaid_box and pararaid_box.visible:
		pararaid_timer -= delta
		if pararaid_timer <= 0.0:
			pararaid_box.visible = false

func show_pararaid_message(speaker: String, text: String, urgent: bool = false) -> void:
	if not pararaid_box:
		return
	pararaid_box.visible = true
	pararaid_timer = 5.0
	pararaid_speaker.text = "// PARA-RAID: %s" % speaker.to_upper()
	pararaid_speaker.modulate = Color(1.0, 0.2, 0.2) if urgent else Color(0.3, 0.85, 1.0)
	pararaid_msg.text = text

func update_base_integrity(curr: float, max_v: float) -> void:
	if base_hp_bar:
		base_hp_bar.max_value = max_v
		base_hp_bar.value = curr
		var pct = int((curr / maxf(max_v, 1.0)) * 100.0)
		base_hp_label.text = " %d%%" % pct
		if pct > 60:
			base_hp_label.modulate = Color(0.3, 1.0, 0.5)
		elif pct > 30:
			base_hp_label.modulate = Color(1.0, 0.85, 0.2)
		else:
			base_hp_label.modulate = Color(1.0, 0.2, 0.2)

func update_allies_status(callsign: String, curr_hp: float, max_hp_v: float) -> void:
	var text = " • %s: %d / %d" % [callsign, int(curr_hp), int(max_hp_v)]
	if "WEHRWOLF" in callsign and ally_wehrwolf_label:
		ally_wehrwolf_label.text = text
		ally_wehrwolf_label.modulate = Color(0.3, 0.85, 1.0) if curr_hp > 0 else Color(0.5, 0.5, 0.5)
	elif "GUNSLINGER" in callsign and ally_gunslinger_label:
		ally_gunslinger_label.text = text
		ally_gunslinger_label.modulate = Color(0.3, 0.85, 1.0) if curr_hp > 0 else Color(0.5, 0.5, 0.5)

func update_legion_counter(count: int) -> void:
	if legion_counter_label:
		legion_counter_label.text = "HOSTILE LEGION: %d REMAINING" % count

func set_timeline(text: String, is_night: bool) -> void:
	if timeline_badge:
		timeline_badge.text = "[ TIMELINE: %s ]" % text
		timeline_badge.modulate = Color(0.5, 0.8, 1.0) if is_night else Color(1.0, 0.85, 0.3)

func show_boss_bar(boss_name: String, curr: float, max_v: float) -> void:
	if boss_bar_panel:
		boss_bar_panel.visible = true
		boss_title_label.text = "[ %s ]" % boss_name
		boss_hp_bar.max_value = max_v
		boss_hp_bar.value = curr

func update_boss_hp(curr: float) -> void:
	if boss_hp_bar:
		boss_hp_bar.value = curr

func hide_boss_bar() -> void:
	if boss_bar_panel:
		boss_bar_panel.visible = false

func show_intermission() -> void:
	if intermission_modal:
		intermission_modal.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_proceed_pressed() -> void:
	if intermission_modal:
		intermission_modal.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		proceed_to_phase_2_requested.emit()

func show_defeat_banner(custom_title: String = "BASE OVERRUN - SECTOR 86 FALLEN", custom_sub: String = "THE FORWARD OUTPOST HAS BEEN DESTROYED BY THE LEGION\nPress [R] to Re-deploy or Return to Base") -> void:
	if banner_box:
		banner_box.visible = true
		banner_title.text = custom_title
		banner_title.modulate = Color(1.0, 0.15, 0.15)
		banner_subtitle.text = custom_sub
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if btn_return_base_banner:
		btn_return_base_banner.mouse_filter = Control.MOUSE_FILTER_STOP

func show_chapter_victory_banner() -> void:
	if banner_box:
		banner_box.visible = true
		banner_title.text = "// CHAPTER 1: MISSION ACCOMPLISHED //"
		banner_title.modulate = Color(0.3, 1.0, 0.6)
		banner_subtitle.text = "FORWARD BASE SECURED & REAR VILLAGE PROTECTED.\nTHE SHEPHERD AND ITS SWARM HAVE BEEN SILENCED.\nPress [R] to Re-deploy or Return to Base"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if btn_return_base_banner:
		btn_return_base_banner.mouse_filter = Control.MOUSE_FILTER_STOP
