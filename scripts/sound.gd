extends Node
## Original, generated placeholder audio. No third-party samples required.
var voices: Array[AudioStreamPlayer] = []
var cues: Dictionary = {}
var cursor: int = 0
var muted: bool = false
var pickup_cooldown: float = 0

func stop_all() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null

func _exit_tree() -> void:
	stop_all()
	cues.clear()

func _ready() -> void:
	for i in range(16):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -15
		add_child(voice)
		voices.append(voice)
	for cue in ["shot", "shotgun", "pickup", "hurt", "ability", "reload", "dash", "slide", "metal", "explosion", "wave"]:
		cues[cue] = _make(cue)

func _process(delta: float) -> void:
	pickup_cooldown = maxf(0, pickup_cooldown - delta / maxf(Engine.time_scale, 0.01))

func play_cue(cue: String) -> void:
	if muted or not cues.has(cue):
		return
	if cue == "pickup":
		if pickup_cooldown > 0:
			return
		pickup_cooldown = 0.10
	var voice := voices[cursor % voices.size()]
	cursor += 1
	voice.stream = cues[cue]
	voice.pitch_scale = 1.0
	voice.play()

func _make(cue: String) -> AudioStreamWAV:
	var rate := 22050
	var duration: float = {"shot": 0.14, "shotgun": 0.25, "pickup": 0.12, "hurt": 0.16, "ability": 0.40, "reload": 0.07, "dash": 0.22, "slide": 0.22, "metal": 0.10, "explosion": 0.6, "wave": 0.5}[cue]
	var count := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = cue.hash()
	var filtered: float = 0
	for i in range(count):
		var t := float(i) / rate
		var progress := float(i) / count
		var envelope := pow(1 - progress, 2.5)
		var noise := random.randf_range(-1, 1)
		filtered = lerpf(filtered, noise, 0.22)
		var sample: float
		match cue:
			"shot", "shotgun", "explosion":
				sample = (filtered * 1.4 + sin(t * TAU * (65 if cue == "explosion" else 115)) * 0.4) * envelope
			"pickup":
				sample = sin(t * TAU * (850 + progress * 500)) * envelope * 0.3
			"ability", "wave":
				sample = (sin(t * TAU * (140 + progress * 280)) * 0.35 + filtered * 0.2) * sin(progress * PI)
			"hurt":
				sample = (sin(t * TAU * 75) + filtered) * envelope * 0.5
			"metal", "reload":
				sample = (noise * 0.3 + sin(t * TAU * 1700) * 0.2) * envelope
			_:
				sample = filtered * sin(progress * PI) * 0.7
		var value := clampi(int(sample * 24000), -32768, 32767)
		bytes.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream
