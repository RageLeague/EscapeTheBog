Content.AddStringTable( "ETB_CONVO_COMMON", {
    CONVO_COMMON = {
        OPT_TRAVEL_ETB = "Travel",
        OPT_MOVE_TO_ETB = "Travel to {1#location}",
        DIALOG_MOVE_TO_ETB = [[
            * You walk towards {1#location}.
        ]],
        OPT_REST_ETB = "Rest",
        DIALOG_REST_ETB = [[
            player:
                !left
                I think I will just rest here.
            * You decide to take a short rest here.
        ]],
        OPT_SLEEP_ETB = "Sleep here",
        DIALOG_SLEEP_ETB = [[
            player:
                !left
                Time for me to go to sleep.
            * You decide to sleep here until you wake up.
        ]],
        DIALOG_SLEEP_EXHAUSTED_ETB = [[
            player:
                !left
                I think I will just...
            * You passed out like a load of bricks.
        ]],
        DIALOG_SLEEP_DOTS_ETB = [[
            * ...
        ]],
        REQ_CAN_SLEEP_ETB = "You are too awake to sleep right now.",
        DIALOG_SLEEP_STARVED_TO_DEATH_ETB = [[
            * This is a sleep that you are never waking up from.
            * You have starved to death in your sleep.
        ]],
        OPT_ACCEPT_DEATH_ETB = "Goodbye",
    }
} )
