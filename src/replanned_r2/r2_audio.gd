## Presentation only. Never reads or mutates combat/save state.
extends Node

const BATTLE_MUSIC = "res://assets/replanned_r2/audio/battle.ogg"

const CUES = {
    "confirm":"res://assets/replanned_r2/audio/confirm.ogg",
    "line":"res://assets/replanned_r2/audio/line.ogg",
    "chain":"res://assets/replanned_r2/audio/chain.ogg",
    "attack":"res://assets/replanned_r2/audio/attack.ogg",
    "enemy":"res://assets/replanned_r2/audio/enemy.ogg",
    "victory":"res://assets/replanned_r2/audio/victory.ogg",
}
var effects: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var background: AudioStreamPlayer
var _battle_active := false
var _battle_paused := false
var _next_voice := 0
var _effects_level := 0.7
var _music_level := 0.5

func _ready():
    for i in 4:
        var player = AudioStreamPlayer.new()
        player.name = "Effect%d" % i
        add_child(player)
        effects.append(player)
    music = AudioStreamPlayer.new()
    music.name = "Music"
    add_child(music)
    background = AudioStreamPlayer.new()
    background.name = "BattleMusic"
    var stream = load(BATTLE_MUSIC).duplicate() as AudioStreamOggVorbis
    stream.loop = true
    background.stream = stream
    add_child(background)
    configure({"effects":70,"music":50})

func configure(levels: Dictionary):
    _effects_level = clampf(float(levels.get("effects",70)),0.0,100.0)/100.0
    _music_level = clampf(float(levels.get("music",50)),0.0,100.0)/100.0
    for player in effects:
        player.volume_linear = _effects_level
        if _effects_level == 0.0: player.stop()
    if music != null:
        music.volume_linear = _music_level
        if _music_level == 0.0: music.stop()
    _sync_background()

func set_battle_state(active: bool, paused: bool):
    _battle_active = active
    _battle_paused = paused
    _sync_background()

func _sync_background():
    if background == null: return
    background.volume_linear = _music_level * 0.35
    if not _battle_active:
        background.stop()
        background.stream_paused = false
        return
    var suspended = _battle_paused or _music_level == 0.0
    background.stream_paused = suspended
    if not suspended and not background.playing: background.play()

func pause_presentation():
    for player in effects: player.stop()
    if music != null: music.stop()
    _battle_paused = true
    _sync_background()

func play_cue(cue: String) -> bool:
    if not CUES.has(cue) or music == null: return false
    var musical = cue == "victory"
    if (musical and _music_level == 0.0) or (not musical and _effects_level == 0.0): return false
    var player = music if musical else effects[_next_voice]
    if not musical: _next_voice = (_next_voice+1)%effects.size()
    player.stream = load(CUES[cue])
    if player.stream == null: return false
    player.play()
    return true

func stop_all():
    for player in effects: player.stop()
    if music != null: music.stop()
    set_battle_state(false,false)

func cue_for_event(event: Dictionary) -> String:
    if not event.get("success",false): return ""
    if event.get("effect","")=="ENEMY_ACTION_RESOLVED" and int(event.get("damage",0))==0: return ""
    return {"ATK_DAMAGE":"attack","LINE_RESOURCES_APPLIED":"line",
        "CHAIN_WAVE_RESOLVED":"chain","ENEMY_ACTION_RESOLVED":"enemy"}.get(event.get("effect",""),"")
