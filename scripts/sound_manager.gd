extends Node

const POLYPHONY: int = 16
const SAMPLE_RATE: int = 22050
const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_MUSIC_PCT: float = 60.0

enum Wave { SINE, SQUARE, NOISE }

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _music_volume_pct: float = DEFAULT_MUSIC_PCT
var _menu_stream: AudioStreamWAV
var _game_stream: AudioStreamWAV

func _ready() -> void:
	for i in range(POLYPHONY):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_generate_sounds()
	_setup_music()

func _setup_music() -> void:
	_music_volume_pct = _load_music_volume_pct()
	_menu_stream = _gen_music_menu()
	_game_stream = _gen_music_game()
	_music_player = AudioStreamPlayer.new()
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.stream = _menu_stream
	_music_player.volume_db = _pct_to_db(_music_volume_pct)
	add_child(_music_player)
	_music_player.play()

func play_menu_music() -> void:
	if _music_player == null:
		return
	if _music_player.stream == _menu_stream and _music_player.playing:
		return
	_music_player.stream = _menu_stream
	_music_player.play()

func play_game_music() -> void:
	if _music_player == null:
		return
	if _music_player.stream == _game_stream and _music_player.playing:
		return
	_music_player.stream = _game_stream
	_music_player.play()

func stop_music() -> void:
	if _music_player:
		_music_player.stop()

func get_music_volume_pct() -> float:
	return _music_volume_pct

func set_music_volume_pct(pct: float) -> void:
	_music_volume_pct = pct
	if _music_player:
		_music_player.volume_db = _pct_to_db(pct)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "music_volume", pct)
	cfg.save(SETTINGS_PATH)

func _load_music_volume_pct() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return DEFAULT_MUSIC_PCT
	return float(cfg.get_value("audio", "music_volume", DEFAULT_MUSIC_PCT))

func _pct_to_db(pct: float) -> float:
	if pct <= 0.0:
		return -80.0
	return linear_to_db(pct / 100.0)

func _generate_sounds() -> void:
	_streams["shoot"]      = _gen(0.04, Wave.SQUARE, 800.0, 400.0, 0.5)
	_streams["hit"]        = _gen(0.05, Wave.NOISE, 0.0, 0.0, 0.5)
	_streams["kill"]       = _gen(0.15, Wave.SINE, 440.0, 110.0, 0.7)
	_streams["pickup"]     = _gen(0.10, Wave.SINE, 440.0, 880.0, 0.7)
	_streams["player_hit"] = _gen(0.20, Wave.NOISE, 0.0, 0.0, 0.9)
	_streams["boss_death"] = _gen(0.60, Wave.NOISE, 0.0, 0.0, 0.8)
	_streams["missile"]    = _gen(0.10, Wave.SQUARE, 200.0, 600.0, 0.5)
	_streams["level_up"]   = _gen_arpeggio(0.08, [523.25, 659.25, 783.99])

func play(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _streams.has(sfx_name):
		return
	var p := _get_free_player()
	p.stream = _streams[sfx_name]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func _get_free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

func _gen(duration: float, wave: int, start_freq: float, end_freq: float, vol: float) -> AudioStreamWAV:
	var n: int = int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase: float = 0.0
	var attack_samples: int = mini(int(0.005 * SAMPLE_RATE), n / 4)
	for i in range(n):
		var freq: float = lerpf(start_freq, end_freq, float(i) / float(n))
		var env: float
		if i < attack_samples:
			env = float(i) / float(attack_samples)
		else:
			env = 1.0 - float(i - attack_samples) / float(n - attack_samples)
		var sval: float
		match wave:
			Wave.SQUARE:
				sval = 1.0 if sin(phase) >= 0.0 else -1.0
			Wave.NOISE:
				sval = randf() * 2.0 - 1.0
			_:
				sval = sin(phase)
		phase += freq / float(SAMPLE_RATE) * TAU
		if phase > TAU:
			phase -= TAU
		var sample: int = clampi(int(sval * env * vol * 32767.0), -32767, 32767)
		data.encode_s16(i * 2, sample)
	return _make_stream(data)

func _gen_arpeggio(note_duration: float, freqs: Array) -> AudioStreamWAV:
	var n_per: int = int(note_duration * SAMPLE_RATE)
	var total: int = n_per * freqs.size()
	var data := PackedByteArray()
	data.resize(total * 2)
	var attack_samples: int = mini(int(0.003 * SAMPLE_RATE), n_per / 4)
	for note_idx in range(freqs.size()):
		var freq: float = freqs[note_idx]
		var phase: float = 0.0
		for i in range(n_per):
			var env: float
			if i < attack_samples:
				env = float(i) / float(attack_samples)
			else:
				env = 1.0 - float(i - attack_samples) / float(n_per - attack_samples)
			phase += freq / float(SAMPLE_RATE) * TAU
			if phase > TAU:
				phase -= TAU
			var sample: int = clampi(int(sin(phase) * env * 0.5 * 32767.0), -32767, 32767)
			data.encode_s16((note_idx * n_per + i) * 2, sample)
	return _make_stream(data)

func _make_stream(data: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SAMPLE_RATE
	s.stereo = false
	s.data = data
	return s

func _gen_music_menu() -> AudioStreamWAV:
	var bpm: float = 140.0
	var beat_dur: float = 60.0 / bpm
	var eighth_dur: float = beat_dur / 2.0
	var beats_per_bar: int = 4
	var bars: int = 8
	var bar_dur: float = beat_dur * float(beats_per_bar)
	var total_dur: float = bar_dur * float(bars)
	var total_samples: int = int(total_dur * float(SAMPLE_RATE))

	# 8-bar progression: Am F G Am | Am F G E (V chord at end builds tension into loop)
	var bass_freqs: Array = [
		110.0, 87.31, 98.0, 110.0,
		110.0, 87.31, 98.0, 82.41,
	]
	# 8 eighth-notes per bar — climbing arpeggio with descent
	var arp_seqs: Array = [
		[220.0, 261.63, 329.63, 440.0, 329.63, 261.63, 220.0, 261.63],
		[174.61, 220.0, 261.63, 349.23, 261.63, 220.0, 174.61, 220.0],
		[196.0, 246.94, 293.66, 392.0, 293.66, 246.94, 196.0, 246.94],
		[220.0, 261.63, 329.63, 440.0, 329.63, 261.63, 220.0, 261.63],
		[220.0, 261.63, 329.63, 440.0, 329.63, 261.63, 220.0, 261.63],
		[174.61, 220.0, 261.63, 349.23, 261.63, 220.0, 174.61, 220.0],
		[196.0, 246.94, 293.66, 392.0, 293.66, 246.94, 196.0, 246.94],
		[164.81, 207.65, 246.94, 329.63, 246.94, 207.65, 164.81, 207.65],
	]

	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var arp_phase: float = 0.0
	var bass_phase: float = 0.0
	var kick_phase: float = 0.0
	var prev_eighth: int = -1
	var prev_beat: int = -1

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat_idx: int = int(t / beat_dur)
		var bar_idx: int = beat_idx / beats_per_bar
		var beat_t: float = fmod(t, beat_dur)
		var eighth_idx: int = int(t / eighth_dur)
		var eighth_in_bar: int = eighth_idx % 8
		var eighth_t: float = fmod(t, eighth_dur)

		if eighth_idx != prev_eighth:
			prev_eighth = eighth_idx
			arp_phase = 0.0
		if beat_idx != prev_beat:
			prev_beat = beat_idx
			bass_phase = 0.0
			kick_phase = 0.0

		var arp_freq: float = float(arp_seqs[bar_idx][eighth_in_bar])
		var bass_freq: float = float(bass_freqs[bar_idx])
		var kick_freq: float = lerpf(140.0, 40.0, minf(beat_t / 0.08, 1.0))

		arp_phase += arp_freq * TAU / float(SAMPLE_RATE)
		bass_phase += bass_freq * TAU / float(SAMPLE_RATE)
		kick_phase += kick_freq * TAU / float(SAMPLE_RATE)

		# Lead arp — square wave, plucky envelope per 8th note
		var arp_attack: float = minf(eighth_t / 0.003, 1.0)
		var arp_decay: float = exp(-3.5 * eighth_t / eighth_dur)
		var arp_env: float = arp_attack * arp_decay
		var arp_wave: float = 1.0 if sin(arp_phase) >= 0.0 else -1.0
		var arp_val: float = arp_wave * arp_env * 0.10

		# Bass — square wave, pulsing per beat
		var bass_attack: float = minf(beat_t / 0.005, 1.0)
		var bass_decay: float = exp(-2.0 * beat_t / beat_dur)
		var bass_env: float = bass_attack * bass_decay
		var bass_wave: float = 1.0 if sin(bass_phase) >= 0.0 else -1.0
		var bass_val: float = bass_wave * bass_env * 0.13

		# Kick drum — sine sweep, very short, on every beat
		var kick_env: float = 0.0
		if beat_t < 0.10:
			kick_env = 1.0 - beat_t / 0.10
		var kick_val: float = sin(kick_phase) * kick_env * 0.40

		var sval: float = clampf(arp_val + bass_val + kick_val, -1.0, 1.0)
		var sample: int = clampi(int(sval * 32767.0), -32767, 32767)
		data.encode_s16(i * 2, sample)

	var s: AudioStreamWAV = _make_stream(data)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = total_samples
	return s

func _gen_music_game() -> AudioStreamWAV:
	var bpm: float = 175.0
	var beat_dur: float = 60.0 / bpm
	var sixteenth_dur: float = beat_dur / 4.0
	var eighth_dur: float = beat_dur / 2.0
	var beats_per_bar: int = 4
	var bars: int = 8
	var bar_dur: float = beat_dur * float(beats_per_bar)
	var total_samples: int = int(bar_dur * float(bars) * float(SAMPLE_RATE))

	# Bar progression: Am Am F G | Am Am F E (V chord at end pulls back to loop)
	var bass_freqs: Array = [
		110.0, 110.0, 87.31, 98.0,
		110.0, 110.0, 87.31, 82.41,
	]
	# 16 sixteenth-notes per bar — driving cascading arpeggios
	var arp_seqs: Array = [
		[220.0, 261.63, 329.63, 440.0, 523.25, 440.0, 329.63, 261.63, 220.0, 261.63, 329.63, 440.0, 329.63, 261.63, 220.0, 174.61],
		[220.0, 261.63, 329.63, 440.0, 523.25, 440.0, 329.63, 261.63, 220.0, 261.63, 329.63, 440.0, 329.63, 261.63, 220.0, 174.61],
		[174.61, 220.0, 261.63, 349.23, 440.0, 349.23, 261.63, 220.0, 174.61, 220.0, 261.63, 349.23, 261.63, 220.0, 174.61, 130.81],
		[196.0, 246.94, 293.66, 392.0, 493.88, 392.0, 293.66, 246.94, 196.0, 246.94, 293.66, 392.0, 293.66, 246.94, 196.0, 146.83],
		[220.0, 261.63, 329.63, 440.0, 523.25, 440.0, 329.63, 261.63, 220.0, 261.63, 329.63, 440.0, 329.63, 261.63, 220.0, 174.61],
		[220.0, 261.63, 329.63, 440.0, 523.25, 440.0, 329.63, 261.63, 220.0, 261.63, 329.63, 440.0, 329.63, 261.63, 220.0, 174.61],
		[174.61, 220.0, 261.63, 349.23, 440.0, 349.23, 261.63, 220.0, 174.61, 220.0, 261.63, 349.23, 261.63, 220.0, 174.61, 130.81],
		[164.81, 207.65, 246.94, 329.63, 415.30, 329.63, 246.94, 207.65, 164.81, 207.65, 246.94, 329.63, 246.94, 207.65, 164.81, 123.47],
	]

	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var arp_phase: float = 0.0
	var bass_phase: float = 0.0
	var kick_phase: float = 0.0
	var snare_phase: float = 0.0
	var prev_sixteenth: int = -1
	var prev_eighth: int = -1
	var prev_beat: int = -1

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat_idx: int = int(t / beat_dur)
		var bar_idx: int = beat_idx / beats_per_bar
		var beat_in_bar: int = beat_idx % beats_per_bar
		var beat_t: float = fmod(t, beat_dur)
		var sixteenth_idx: int = int(t / sixteenth_dur)
		var sixteenth_in_bar: int = sixteenth_idx % 16
		var sixteenth_t: float = fmod(t, sixteenth_dur)
		var eighth_idx: int = int(t / eighth_dur)
		var eighth_t: float = fmod(t, eighth_dur)

		if sixteenth_idx != prev_sixteenth:
			prev_sixteenth = sixteenth_idx
			arp_phase = 0.0
		if eighth_idx != prev_eighth:
			prev_eighth = eighth_idx
			bass_phase = 0.0
		if beat_idx != prev_beat:
			prev_beat = beat_idx
			kick_phase = 0.0
			snare_phase = 0.0

		var arp_freq: float = float(arp_seqs[bar_idx][sixteenth_in_bar])
		var bass_freq: float = float(bass_freqs[bar_idx])
		var kick_freq: float = lerpf(150.0, 38.0, minf(beat_t / 0.08, 1.0))

		arp_phase += arp_freq * TAU / float(SAMPLE_RATE)
		bass_phase += bass_freq * TAU / float(SAMPLE_RATE)
		kick_phase += kick_freq * TAU / float(SAMPLE_RATE)
		snare_phase += 220.0 * TAU / float(SAMPLE_RATE)

		# Lead arp — square wave, very plucky 16ths
		var arp_attack: float = minf(sixteenth_t / 0.002, 1.0)
		var arp_decay: float = exp(-4.0 * sixteenth_t / sixteenth_dur)
		var arp_env: float = arp_attack * arp_decay
		var arp_wave: float = 1.0 if sin(arp_phase) >= 0.0 else -1.0
		var arp_val: float = arp_wave * arp_env * 0.08

		# Bass — square wave, pulse on every 8th
		var bass_attack: float = minf(eighth_t / 0.003, 1.0)
		var bass_decay: float = exp(-3.0 * eighth_t / eighth_dur)
		var bass_env: float = bass_attack * bass_decay
		var bass_wave: float = 1.0 if sin(bass_phase) >= 0.0 else -1.0
		var bass_val: float = bass_wave * bass_env * 0.11

		# Kick on every beat
		var kick_env: float = 0.0
		if beat_t < 0.10:
			kick_env = 1.0 - beat_t / 0.10
		var kick_val: float = sin(kick_phase) * kick_env * 0.42

		# Snare on beats 2 and 4 (backbeat)
		var snare_val: float = 0.0
		if (beat_in_bar == 1 or beat_in_bar == 3) and beat_t < 0.07:
			var snare_env: float = 1.0 - beat_t / 0.07
			var noise: float = randf() * 2.0 - 1.0
			snare_val = (noise * 0.7 + sin(snare_phase) * 0.3) * snare_env * 0.30

		# Hi-hat on every 16th — quick noise tick
		var hh_val: float = 0.0
		if sixteenth_t < 0.012:
			var hh_env: float = 1.0 - sixteenth_t / 0.012
			hh_val = (randf() * 2.0 - 1.0) * hh_env * 0.06

		var sval: float = clampf(arp_val + bass_val + kick_val + snare_val + hh_val, -1.0, 1.0)
		var sample: int = clampi(int(sval * 32767.0), -32767, 32767)
		data.encode_s16(i * 2, sample)

	var s: AudioStreamWAV = _make_stream(data)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = total_samples
	return s
