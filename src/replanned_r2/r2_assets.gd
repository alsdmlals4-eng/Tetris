## Immutable published candidates, explicitly reused for isolated runtime trial.
extends RefCounted
const DATA_PATH := "res://docs/design/r2-complete-session.json"
const TILE_REGIONS := {"A":"attack","D":"defense","H":"healing","T":"time"}
const ENEMY_POSES := ["idle","anticipation","impact","recovery","hurt","defeat"]
var metadata: Dictionary = {}
var errors: Array[String] = []
var _atlases := {}
var _regions := {}

func _asset_source_root(source_root_override: String) -> String:
    if not source_root_override.is_empty():
        return source_root_override
    var environment_root := OS.get_environment("TETRIS_R2_SOURCE_ASSET_ROOT")
    if not environment_root.is_empty():
        return environment_root
    if OS.has_feature("editor"):
        return ""
    return OS.get_executable_path().get_base_dir().path_join("r2-source-assets")

func _init(source_root_override: String = ""):
    var source = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    if not source is Dictionary:
        errors.append("R2 asset manifest missing")
        return
    metadata = source.assets
    var source_root: String = _asset_source_root(source_root_override)
    for id in metadata:
        var entry: Dictionary = metadata[id]
        var path = "res://"+String(entry.path)
        var hash_path: String = path if source_root.is_empty() else source_root.path_join(String(entry.path))
        if FileAccess.get_sha256(hash_path) != entry.sha256:
            errors.append("Asset hash mismatch: "+id)
            continue
        var atlas = load(path) as Texture2D
        if atlas == null or atlas.get_size() != Vector2(entry.size[0],entry.size[1]):
            errors.append("Asset missing or wrong size: "+id)
            continue
        _atlases[id] = atlas
        for pose in entry.regions:
            var r: Array = entry.regions[pose]
            var region = AtlasTexture.new()
            region.atlas = atlas
            region.region = Rect2(r[0],r[1],r[2],r[3])
            region.filter_clip = true
            _regions[id+":"+pose] = region
func texture(id: String, region: String) -> AtlasTexture:
    return _regions.get(id+":"+region)
func tile(symbol: String) -> AtlasTexture:
    return texture("R2-TILES",TILE_REGIONS.get(symbol,"attack"))

func enemy_binding(encounter_id: String) -> Dictionary:
    if encounter_id not in ["","rift_breaker_r2_intro","outer_breach","foundry","watchtower","rift_core"]:
        return {"success":false,"reason":"UNKNOWN_ENEMY"}
    # The shared trial is explicit. Do not use portraits or unreviewed vault files.
    for pose in ENEMY_POSES:
        if texture("R2-BOSS",pose)==null:
            return {"success":false,"reason":"INCOMPLETE_ENEMY_POSES"}
    return {"success":true,"asset_id":"R2-BOSS",
        "state":"SHARED_TRIAL_FALLBACK" if encounter_id in ["outer_breach","foundry","watchtower"] else "CANDIDATE_RUNTIME_TRIAL_PENDING_FINAL_USER_REVIEW"}

func enemy_texture(encounter_id: String, pose: String) -> AtlasTexture:
    var binding = enemy_binding(encounter_id)
    if not binding.success or pose not in ENEMY_POSES: return null
    return texture(binding.asset_id,pose)
func consumer_manifest() -> Dictionary:
    return {"state":"CANDIDATE_RUNTIME_TRIAL_PENDING_FINAL_USER_REVIEW","assets":metadata.duplicate(true),
        "consumers":{"R2-TILES":"Battle/Puzzle/Line and Chain cells; ghost; HOLD/NEXT",
            "R2-BOSS":"Battle/Combat/Stage/BodyClip/BossVisual; Main/Boss; Result/BossVisual",
            "R1-PORTRAIT":"Battle/Combat/PlayerHUD/Portrait; Result/Portrait",
            "R1-ICONS":"Battle/Combat/SkillDock and Threat",
            "R1-ENV":"Backdrop; Battle/Combat/Stage/Backdrop"}}
