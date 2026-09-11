## Immutable published candidates, explicitly reused for isolated runtime trial.
extends RefCounted
const DATA_PATH := "res://docs/design/r2-complete-session.json"
const TILE_REGIONS := {"A":"attack","D":"defense","H":"healing","T":"time"}
var metadata: Dictionary = {}
var errors: Array[String] = []
var _atlases := {}
var _regions := {}
func _init():
    var source = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    if not source is Dictionary:
        errors.append("R2 asset manifest missing")
        return
    metadata = source.assets
    for id in metadata:
        var entry: Dictionary = metadata[id]
        var path = "res://"+String(entry.path)
        if FileAccess.get_sha256(path) != entry.sha256:
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
func consumer_manifest() -> Dictionary:
    return {"state":"CANDIDATE_RUNTIME_TRIAL_PENDING_FINAL_USER_REVIEW","assets":metadata.duplicate(true),
        "consumers":{"R2-TILES":"Battle/Puzzle/Line and Chain cells; ghost; HOLD/NEXT",
            "R2-BOSS":"Battle/Combat/Stage/BodyClip/BossVisual; Main/Boss; Result/BossVisual",
            "R1-PORTRAIT":"Battle/Combat/PlayerHUD/Portrait; Result/Portrait",
            "R1-ICONS":"Battle/Combat/SkillDock and Threat",
            "R1-ENV":"Backdrop; Battle/Combat/Stage/Backdrop"}}
