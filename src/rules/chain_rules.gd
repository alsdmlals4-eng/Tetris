class_name ChainRules
extends RefCounted

const STOCK_CAP := 5

static func stock_value(chain_count: int) -> int:
    return clampi(chain_count, 0, STOCK_CAP)

static func make_completed_event(chain_count: int, pieces_cleared: int) -> Dictionary:
    return {
        "kind": &"chain_complete",
        "chain_count": chain_count,
        "stock_value": stock_value(chain_count),
        "pieces_cleared": maxi(pieces_cleared, 0),
    }
