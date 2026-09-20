## Keeps the verified credit/replay ledger; overflow is spendable by session.
extends "res://src/replanned_r3/r3_pair_supply.gd"
const CONFIG="res://data/replanned_r3/assist.json"
func _init():
    super()
    _rules.cap=int(JSON.parse_string(FileAccess.get_file_as_string(CONFIG)).supply_cap)
func _rules_hash()->String:
    return (super._rules_hash()+":"+FileAccess.get_sha256(CONFIG)).sha256_text()
