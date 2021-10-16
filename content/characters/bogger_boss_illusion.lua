local DEFS = {
    CharacterDef("BOGGER_BOSS_KALANDRA",
    {
        base_def = "BOGGER_BOSS",
    },
    CharacterDef("BOGGER_BOSS_FELLEMO",
    {
        base_def = "BOGGER_BOSS",
    },
}

for _, def in pairs(DEFS) do
    Content.AddCharacterDef( def )
    -- character_def:InheritBaseDef()
    Content.GetCharacterDef(def.id):InheritBaseDef()
end
