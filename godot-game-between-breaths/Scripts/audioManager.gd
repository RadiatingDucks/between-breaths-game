extends Node

#commented by ChatGPT
# ------------------------------
# Preload sound effects
# ------------------------------
var sounds := {
	"jump_land": preload("res://sounds/pop-cartoon-328167.mp3"),
	"walk": preload("res://sounds/Walking fast on Grass.mp3"),
	"splash": preload("res://sounds/Jump In Shallow Water.mp3"),
	"swim": preload("res://sounds/creek-swimming-6728.mp3")
}

# Preload background music
var music_tracks := {
	"bg": preload("res://sounds/jungle-ish-beat-for-video-games-314073.mp3")
}

# ------------------------------
# Internal storage
# ------------------------------
var players: Dictionary = {}   # Dictionary of AudioStreamPlayers for sound effects
var music_player: AudioStreamPlayer # Separate player for music
var current_music: String = "" # Track which music is currently playing

# ------------------------------
# Initialization
# ------------------------------
func _ready():
	# Create a dedicated AudioStreamPlayer for each sound effect
	for name in sounds.keys():
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.stream = sounds[name]
		players[name] = player
	
	# Create a dedicated AudioStreamPlayer for background music
	music_player = AudioStreamPlayer.new()
	music_player.stream = null
	music_player.autoplay = false
	music_player.bus = "Music"  # Optional: route to a custom "Music" bus in Audio panel
	music_player.stream_paused = false
	music_player.volume_db = 0
	add_child(music_player)

# ------------------------------
# Sound effects
# ------------------------------

# Play a sound effect once (restarts if already playing)
func play_sound(name: String):
	if players.has(name):
		var p = players[name]
		p.stop()
		p.play()

# Play a looping sound effect (only starts if not already playing)
func play_loop(name: String):
	if players.has(name):
		var p = players[name]
		p.stream.loop = true
		if not p.playing:
			p.play()

# Stop a looping sound effect
func stop_sound(name: String):
	if players.has(name):
		players[name].stop()

# ------------------------------
# Music control
# ------------------------------

# Play background music (optionally looped)
func play_music(stream: AudioStream, loop: bool = true):
	if music_player.stream == stream and music_player.playing:
		return # Already playing this track
	music_player.stop()
	music_player.stream = stream
	music_player.stream.loop = loop
	music_player.play()
	current_music = stream.resource_path

# Stop background music
func stop_music():
	music_player.stop()
	current_music = ""
