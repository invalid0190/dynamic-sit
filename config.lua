Config = {}

Config.Debug = false -- Enable for testing raycasts

-- General offsets
Config.PushOut = 0.01

-- Height thresholds
Config.Height = {
    Ledge = 0.4,
    Bench = 0.8,
    Lean = 1.3
}

-- Final Calibrated Zero-Setback Offsets
-- With forward set to 0.0, the player snaps exactly to the wall's pivot point.
-- The foolproof normal ensures they face the correct direction away from the wall.
Config.Offsets = {
    edge_fall = { forward = -0.03, z = 2.0 },
    ledge     = { forward = -0.3, z = 1.05 },
    bench     = { forward = -0.2, z = 1.0 },
    lean      = { forward = 0.1, z = 0.0 },
    ground    = { forward = 0.1, z = -0.95 }
}

Config.Scenarios = {
    "WORLD_HUMAN_SEAT_WALL",
    "WORLD_HUMAN_SEAT_LEDGE",
    "PROP_HUMAN_SEAT_BENCH",
    "PROP_HUMAN_SEAT_CHAIR",
    "PROP_HUMAN_SEAT_BUS_STOP_WAIT",
    "PROP_HUMAN_SEAT_ARMCHAIR",
    "PROP_HUMAN_SEAT_STRIP_WATCH"
}
