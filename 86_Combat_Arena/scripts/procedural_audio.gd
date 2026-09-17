class_name ProceduralAudio
extends RefCounted

static var cannon_stream: AudioStream = preload("res://assets/audio/cannon_fire_57mm.wav")
static var explosion_stream: AudioStream = preload("res://assets/audio/explosion_57mm.wav")
static var armor_hit_stream: AudioStream = preload("res://assets/audio/armor_hit.wav")
static var wall_hit_stream: AudioStream = preload("res://assets/audio/wall_hit.wav")
static var ambient_wind_stream: AudioStream = preload("res://assets/audio/ambient_forest_wind.wav")
static var alarm_chime_stream: AudioStream = preload("res://assets/audio/cockpit_alarm_chime.wav")
static var catastrophic_stream: AudioStream = preload("res://assets/audio/catastrophic_detonation.wav")
static var tree_snap_stream: AudioStream = preload("res://assets/audio/tree_snap.wav")
static var tree_fall_impact_stream: AudioStream = preload("res://assets/audio/tree_fall_impact.wav")
static var concrete_shatter_stream: AudioStream = preload("res://assets/audio/concrete_shatter.wav")
static var ammo_detonation_stream: AudioStream = preload("res://assets/audio/ammo_detonation.wav")

static var footstep_streams: Array[AudioStream] = [
	preload("res://assets/audio/footstep_01.wav"),
	preload("res://assets/audio/footstep_02.wav"),
	preload("res://assets/audio/footstep_03.wav"),
	preload("res://assets/audio/footstep_04.wav"),
]
static var current_footstep_idx: int = 0

static func create_cannon_sound() -> AudioStream:
	return cannon_stream

static func create_explosion_sound() -> AudioStream:
	return explosion_stream

static func create_hit_sound() -> AudioStream:
	return armor_hit_stream

static func create_footstep_sound() -> AudioStream:
	var stream = footstep_streams[current_footstep_idx]
	current_footstep_idx = (current_footstep_idx + 1) % footstep_streams.size()
	return stream

static func create_wall_hit_sound() -> AudioStream:
	return wall_hit_stream

static func create_ambient_wind_sound() -> AudioStream:
	return ambient_wind_stream

static func create_alarm_sound() -> AudioStream:
	return alarm_chime_stream

static func create_catastrophic_sound() -> AudioStream:
	return catastrophic_stream

static func create_tree_snap_sound() -> AudioStream:
	return tree_snap_stream

static func create_tree_fall_sound() -> AudioStream:
	return tree_fall_impact_stream

static func create_concrete_shatter_sound() -> AudioStream:
	return concrete_shatter_stream

static func create_ammo_detonation_sound() -> AudioStream:
	return ammo_detonation_stream

