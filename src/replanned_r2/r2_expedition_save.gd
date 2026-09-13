## Separate campaign envelope reuses the existing readback/backup writer.
extends "res://src/replanned_r2/r2_save.gd"

const Expedition = preload("res://src/replanned_r2/r2_expedition.gd")
const EXPEDITION_PATH := "user://replanned_r2/expedition.json"

func _init(path: String = EXPEDITION_PATH):
    super(path)

func save_expedition(expedition, session, clock_remainder_ns: int = 0) -> Dictionary:
    if expedition == null or not _integer(clock_remainder_ns,0,999): return _error("INVALID_EXPEDITION")
    if session != null and not session.can_checkpoint(): return _error("CASCADE_OR_TRANSACTION_UNSTABLE")
    var payload := {"schema":"r2-expedition-disk-v1", "expedition":expedition.snapshot(),
        "battle":null if session == null else session.snapshot(), "clock_remainder_ns":clock_remainder_ns}
    payload["checksum"] = canonical_json(payload).sha256_text()
    return _replace(save_path,payload,false)

func load_expedition() -> Dictionary:
    for suffix in ["", ".bak"]:
        var payload := _read_valid(save_path+suffix,false)
        if payload.is_empty(): continue
        var result := _decode(payload)
        result["source"] = "primary" if suffix.is_empty() else "backup"
        return result
    return _error("이어갈 수 있는 온전한 원정 기록이 없습니다.")

func _valid_payload(value: Dictionary, options: bool) -> bool:
    if options: return super._valid_payload(value,true)
    if value.size() != 5 or value.get("schema") != "r2-expedition-disk-v1": return false
    if not value.get("checksum") is String: return false
    var body := value.duplicate(true)
    body.erase("checksum")
    if canonical_json(body).sha256_text() != value.checksum: return false
    return _decode(value).success

func _decode(value: Dictionary) -> Dictionary:
    if not value.get("expedition") is Dictionary or not _integer(value.get("clock_remainder_ns"),0,999): return _error("INVALID_ENVELOPE")
    var expedition = Expedition.new()
    if not expedition.restore(value.expedition): return _error("INVALID_ROUTE")
    var state: Dictionary = expedition.view()
    var session = null
    if state.phase == "ROUTE":
        if value.get("battle") != null or int(value.clock_remainder_ns) != 0: return _error("ROUTE_HAS_LIVE_BATTLE")
    else:
        if not value.get("battle") is Dictionary: return _error("MISSING_BATTLE")
        var meta: Dictionary = state.active_battle
        session = Session.new(meta.difficulty, int(meta.seed), meta.run_id, meta.encounter_id)
        var expected_line: Dictionary = session.line.snapshot()
        var expected_chain: Dictionary = session.chain.snapshot()
        if not session.restore(value.battle): return _error("INVALID_BATTLE")
        var restored_line: Dictionary = session.line.snapshot()
        for key in ["shape_seed", "resource_seed"]:
            if restored_line[key] != expected_line[key]: return _error("BATTLE_SEED_MISMATCH")
        if session.chain.snapshot().seed != expected_chain.seed: return _error("BATTLE_SEED_MISMATCH")
        if session.run_id != meta.run_id or session.encounter_mode != meta.difficulty or session.training_mode != "": return _error("BATTLE_IDENTITY_MISMATCH")
        var expected := "RUNNING" if state.phase == "BATTLE" else ("DEFEAT" if state.phase == "DEFEAT" else "VICTORY")
        if session.combat.outcome != expected: return _error("BATTLE_PHASE_MISMATCH")
        if state.phase != "BATTLE" and session.combat.hp != state.hp: return _error("RESULT_HP_MISMATCH")
    return {"success":true,"reason":"","expedition":expedition,"session":session,
        "clock_remainder_ns":int(value.clock_remainder_ns)}
