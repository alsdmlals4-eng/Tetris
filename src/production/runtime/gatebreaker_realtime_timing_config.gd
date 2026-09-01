## Gatebreaker authored 행동별 realtime ETA seed를 fail-closed로 읽는다.
class_name GatebreakerRealtimeTimingConfig
extends RefCounted

const REQUIRED_ACTION_KEYS := [
    "light_smash",
    "gatebreaker_slam",
    "rift_siphon",
    "chain_fracture",
    "rift_repair",
    "siege_charge",
]

var balance_status: String = ""
var commit_lead_seconds: float = 0.0
var tutorial_opening_eta_seconds: float = 0.0
var tutorial_nonterminal_until_first_confirm := false
var _action_seconds: Dictionary = {}

static func from_dictionary(data: Dictionary):
    if String(data.get("balance_status", "")) != "TUNING_SEED_NOT_FINAL":
        return null
    var lead := float(data.get("commit_lead_seconds", -1.0))
    if lead < 0.0:
        return null
    var tutorial_opening_eta := float(data.get("tutorial_opening_eta_seconds", -1.0))
    if tutorial_opening_eta <= 0.0 or not (data.get("tutorial_nonterminal_until_first_confirm") is bool):
        return null
    var action_seconds = data.get("action_seconds")
    if not action_seconds is Dictionary:
        return null
    var normalized: Dictionary = {}
    for action_key in REQUIRED_ACTION_KEYS:
        var seconds := float(action_seconds.get(action_key, 0.0))
        if seconds <= 0.0:
            return null
        normalized[action_key] = seconds
    var config := GatebreakerRealtimeTimingConfig.new()
    config.balance_status = String(data["balance_status"])
    config.commit_lead_seconds = lead
    config.tutorial_opening_eta_seconds = tutorial_opening_eta
    config.tutorial_nonterminal_until_first_confirm = bool(data["tutorial_nonterminal_until_first_confirm"])
    config._action_seconds = normalized
    return config

func seconds_for_action(action_key: String) -> float:
    if not _action_seconds.has(action_key):
        return -1.0
    return float(_action_seconds[action_key])

func opening_seconds_for_action(action_key: String, use_tutorial_opening: bool) -> float:
    if use_tutorial_opening:
        return tutorial_opening_eta_seconds
    return seconds_for_action(action_key)
