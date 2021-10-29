local filepath = require "util/filepath"

local function OnPostLoad( mod )
    local STARTING_MONEY = 125

    local FORBIDDEN_CONVO = {

    }

    local ACT_DATA = {
        id = "ESCAPE_THE_BOG",
        name = "Escape The Bog",
        title = "The Bog consumes all",
        desc = "Use your wits and improvisation skills to survive and escape the bog.",

        -- act_image = engine.asset.Texture("DEMOCRATICRACE:assets/icons/campaign_icon.png"),
        colour_frame = "0xedbb7bff",
        colour_text = "0xd89e52ff",
        colour_background = "0x895817ff",

        world_region = "grout_bog",

        main_quest = "ESCAPE_THE_BOG_MAIN",
        game_type = GAME_TYPE.CAMPAIGN,

        -- slides = {
        --     "democracy_intro_slides",
        -- },

        starting_fn = function(agent)
            agent:DeltaMoney( STARTING_MONEY )
        end,

        convo_filter_fn = function( convo_def, game_state )
            if table.arraycontains(FORBIDDEN_CONVO, convo_def.id) then
                return false
            end

            return true
        end,

        score_modifiers =
        {
            money = -STARTING_MONEY,
        }
    }

    for id, data in pairs(GetAllPlayerBackgrounds()) do
        local act_data = shallowcopy(ACT_DATA)
        act_data.id = data.id .. "_" .. act_data.id
        data:AddAct(act_data)
        Content.internal.ACT_DATA[act_data.id] = data.acts[#data.acts]
    end

    -- In postload to account for modded items.
    require "ESCAPE_THE_BOG:content/food_items"
end

local function OnLoad( mod )
    rawset(_G, "CURRENT_MOD_ID", mod.id)

    for k, filepath in ipairs( filepath.list_files( "ESCAPE_THE_BOG:patches/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if name then
            require( name )
        end
    end

    for k, filepath in ipairs( filepath.list_files( "ESCAPE_THE_BOG:ui/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if name then
            require( name )
        end
    end

    require "ESCAPE_THE_BOG:content/util"
    require "ESCAPE_THE_BOG:content/convo_loc_common"
    require "ESCAPE_THE_BOG:content/combat_parties"
    require "ESCAPE_THE_BOG:content/custom_card_rewards"

    for k, filepath in ipairs( filepath.list_files( "ESCAPE_THE_BOG:content/aspects/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if name then
            require( name )
        end
    end

    for k, filepath in ipairs( filepath.list_files( "ESCAPE_THE_BOG:content/battle/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if name then
            require( name )
        end
    end

    for k, filepath in ipairs( filepath.list_files( "ESCAPE_THE_BOG:content/negotiation/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if name then
            require( name )
        end
    end

    for k, filepath in ipairs( filepath.list_files( "ESCAPE_THE_BOG:content/characters/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if name then
            require( name )
        end
    end

    for k, filepath in ipairs( filepath.list_files( "ESCAPE_THE_BOG:content/quests/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if filepath:find( "/deprecated/" ) then
        else
            if name then
                -- package.loaded[ name ] = nil
                require( name )
                -- assert( rawget( _G, "QDEF" ) == nil or error( string.format( "Stop declaring global QDEFS %s", name )))
            end
        end
    end

    for k, filepath in ipairs( filepath.list_files( "ESCAPE_THE_BOG:content/convo/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if name then
            require( name )
        end
    end



    return OnPostLoad
end

local MOD_OPTIONS =
{
    -- Access this value from the user's settings by calling:
    -- Content.GetModSetting( <mod_id>, "resolve_per_day" )
    {
        title = "Number of Locations",
        slider = true,
        key = "number_of_locations",
        default_value = 15,
        values = {
            range_min = 3,
            range_max = 50,
            step_size = 1,
            desc = "This sets the number of generic locations to be spawned in a run of Escape the Bog.",
        },
    },
}

return {
    version = "0.0.1",
    alias = "ESCAPE_THE_BOG",

    OnLoad = OnLoad,

    mod_options = MOD_OPTIONS,

    title = "Escape The Bog",
    description = "A mini campaign for Griftlands where you try to escape your inevitable demise.",
    previewImagePath = "preview.png",
}
