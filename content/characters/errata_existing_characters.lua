local ERRATA_FIELDS =
{
    LUMINTHIAN =
    {
        etb_slow_flee = true,
    },
    GRAWKIT =
    {
        etb_slow_flee = true,
    },
}

for id, data in pairs(ERRATA_FIELDS) do
    local def = Content.GetCharacterDef(id)
    for k, v in pairs(data) do
        def[k] = v
    end
end
