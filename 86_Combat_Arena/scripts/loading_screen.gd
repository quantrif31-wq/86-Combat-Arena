extends Control
class_name LoadingScreen

const TARGET_SCENE_PATH = "res://scenes/main_arena.tscn"
const SFX_SYNC = preload("res://assets/audio/pararaid_sync.wav")

@onready var progress_bar: ProgressBar = $CenterBox/ProgressBar
@onready var percent_label: Label = $CenterBox/ProgressInfo/PercentLabel
@onready var telemetry_log: Label = $CenterBox/TelemetryLog
@onready var quote_label: Label = $BottomBox/QuoteLabel
@onready var waveform_display: Control = $CenterBox/WaveformBox/VBox/WaveformCanvas
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var fade_curtain: ColorRect = $FadeCurtain

var load_progress: Array = []
var visual_progress: float = 0.0
var elapsed_time: float = 0.0
var min_load_duration: float = 2.8 # Ensures player enjoys the cinematic 86 atmosphere
var is_finishing: bool = false

var quotes: Array[String] = [
	"\"The Republic has no casualties in war. Because we, the Eighty-Six, are not counted as human.\"",
	"\"If you ever make it to where we fell... please leave a flower for us.\"",
	"\"We are going on ahead. See you tomorrow, Handler One.\"",
	"\"Even if our names fade from memory, the reaper will carry us to the final destination.\"",
	"\"I don't want to die. But more than that, I refuse to run from who I am.\""
]
var quote_index: int = 0
var quote_timer: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	
	# Start threaded loading of the main arena
	var err = ResourceLoader.load_threaded_request(TARGET_SCENE_PATH)
	if err != OK:
		push_error("Failed to start threaded loading for: " + TARGET_SCENE_PATH)
		
	# Play Para-RAID neural sync chime
	if sfx_player:
		sfx_player.stream = SFX_SYNC
		sfx_player.volume_db = -3.0
		sfx_player.play()
		
	# Initial random quote
	quotes.shuffle()
	quote_label.text = quotes[0]
	
	# Fade in from black
	fade_curtain.visible = true
	fade_curtain.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_curtain, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD)

func _process(delta: float) -> void:
	elapsed_time += delta
	quote_timer += delta
	
	if quote_timer > 3.2:
		quote_timer = 0.0
		quote_index = (quote_index + 1) % quotes.size()
		var q_tween = create_tween()
		q_tween.tween_property(quote_label, "modulate:a", 0.0, 0.3)
		q_tween.tween_callback(func(): quote_label.text = quotes[quote_index])
		q_tween.tween_property(quote_label, "modulate:a", 1.0, 0.4)
		
	# Poll ResourceLoader
	var status = ResourceLoader.load_threaded_get_status(TARGET_SCENE_PATH, load_progress)
	var real_progress: float = 0.0
	if load_progress.size() > 0:
		real_progress = load_progress[0]
		
	# Time-weighted target progress: smooth curve
	var time_ratio = clampf(elapsed_time / min_load_duration, 0.0, 1.0)
	var target_progress = minf(real_progress, time_ratio)
	if status == ResourceLoader.THREAD_LOAD_LOADED and elapsed_time >= min_load_duration:
		target_progress = 1.0
		
	visual_progress = move_toward(visual_progress, target_progress, delta * 0.75)
	
	# Update UI
	var pct = int(visual_progress * 100.0)
	progress_bar.value = visual_progress * 100.0
	percent_label.text = "[ %3d %% ]" % pct
	
	_update_telemetry(visual_progress)
	
	# Check for completion
	if status == ResourceLoader.THREAD_LOAD_LOADED and visual_progress >= 0.999 and not is_finishing:
		is_finishing = true
		_on_loading_complete()

func _update_telemetry(progress: float) -> void:
	if progress < 0.22:
		telemetry_log.text = "[01/05] PARA-RAID NEURAL RESONANCE: LINKING SENSORY CORRIDOR (96.48 MHz)..."
	elif progress < 0.45:
		telemetry_log.text = "[02/05] M1A4 JUGGERNAUT AVIONICS: 4-LEG ACTUATORS PRESSURIZED & SYNCHRONIZED"
	elif progress < 0.70:
		telemetry_log.text = "[03/05] FIRE CONTROL SYSTEM: 57MM HIGH-VELOCITY BREECH LOCKED // APFSDS READY"
	elif progress < 0.92:
		telemetry_log.text = "[04/05] BATTLEFIELD TELEMETRY: SECTOR 86 GRAND WARZONE TOPOGRAPHY LOADED"
	else:
		telemetry_log.text = "[05/05] NEURAL LINK LOCKED // SPEARHEAD SQUADRON 01: COMMENCING COMBAT SORTIE!"

func _on_loading_complete() -> void:
	# Subtle pause on 100% to read lock confirmation, then smooth fade
	await get_tree().create_timer(0.45).timeout
	
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_curtain, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	await fade_tween.finished
	
	var loaded_resource = ResourceLoader.load_threaded_get(TARGET_SCENE_PATH)
	if loaded_resource is PackedScene:
		get_tree().change_scene_to_packed(loaded_resource)
	else:
		get_tree().change_scene_to_file(TARGET_SCENE_PATH)
