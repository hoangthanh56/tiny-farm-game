extends AudioStreamPlayer
## Small original synthesized sound effects, with no external asset dependency.

var muted := false
var sounds: Array[AudioStreamWAV] = []

func _ready() -> void:
	volume_db = -15
	for frequency in [180.0, 420.0, 650.0, 880.0, 540.0]:
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = 22050
		var samples := PackedByteArray()
		var count := 4400
		samples.resize(count * 2)
		for i in range(count):
			var t := float(i) / 22050.0
			var envelope := sin(PI * float(i) / count) * (1.0 - float(i) / count)
			var sample := int(sin(TAU * frequency * t + t * t * 2000) * envelope * 15000)
			samples.encode_s16(i * 2, sample)
		wav.data = samples
		sounds.append(wav)

func effect(index: int) -> void:
	if muted or sounds.is_empty():
		return
	stop()
	stream = sounds[clampi(index, 0, sounds.size() - 1)]
	play()

func _exit_tree() -> void:
	stop()
	stream = null
	sounds.clear()
