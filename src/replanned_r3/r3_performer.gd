## Isolated candidate art trial, not final-art approval or an R2 replacement.
extends RefCounted
const ROOT="res://docs/assets/reference/planned/replanning/skill-performer-20260914/"
var errors:Array=[]
var _regions:Dictionary={}

func _init():
    var contract=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest-v2.json"))
    if not contract is Dictionary:
        errors.append("PERFORMER_MANIFEST_INVALID")
        return
    if FileAccess.get_sha256(ROOT+"performer-atlas-v2.png")!=contract.atlas_sha256:
        errors.append("PERFORMER_HASH_MISMATCH")
        return
    var atlas=load(ROOT+"performer-atlas-v2.png") as Texture2D
    if atlas==null or atlas.get_size()!=Vector2(1344,1344):
        errors.append("PERFORMER_TEXTURE_INVALID")
        return
    for frame in contract.frames:
        if frame.source_side_contact_pixels!=0:
            errors.append("PERFORMER_CLIPPED_SOURCE")
            _regions.clear()
            return
        var texture=AtlasTexture.new()
        texture.atlas=atlas
        texture.region=Rect2(frame.region[0],frame.region[1],frame.region[2],frame.region[3])
        texture.filter_clip=true
        _regions[frame.category+":"+frame.phase]=texture

func texture(category:String,phase:String)->AtlasTexture:
    return _regions.get(category+":"+("impact" if phase=="compact" else phase))
