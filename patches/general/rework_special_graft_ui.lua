-- This patch reworks the UI of Widget.PickGraftOption to allow more graft types
-- to be displayed properly in the graft draft UI.
-- For example, it can allow the UI for coin graft draft or social boon draft to
-- be displayed properly.
-- To use it, simply copy the content of this file to your own mod and load it.
-- You may modify the content of the tables below to make it better suit your need.
-- It is designed to be compatible with other mods that uses this patch.

-- MIT License

-- Copyright (c) 2021 RageLeague

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

require "ui/widgets/optionpicker"
require "ui/widgets/screen"
require "ui/widgets/tooltip_graft"
require "ui/screens/replacegraftscreen"

-- Defines the colors for these graft types.
-- Each entry can be an integer representing the color, or a function that takes
-- a graft as a parameter and returns an integer representing the color.
-- You may add additional entries here to expand to more graft types.
-- The patch is loaded earlier takes precedence in terms of entries loaded.
local GRAFT_COLORS = {
    [GRAFT_TYPE.NEGOTIATION] = UICOLOURS.NEGOTIATION,
    [GRAFT_TYPE.COMBAT] = UICOLOURS.FIGHT,
    [GRAFT_TYPE.COIN] = UICOLOURS.MONEY,
    [GRAFT_TYPE.SOCIAL] = function(graft)
        return graft:GetDef().is_good and UICOLOURS.RELATIONSHIP_LOVED or UICOLOURS.RELATIONSHIP_HATED
    end,
}

-- Defines the name for these graft types.
-- Each entry can be a string representing the localization ID of the text, or
-- a function that takes a graft as a parameter and returns a string
-- representing the localization ID of the text.
-- You may add additional entries here to expand to more graft types.
-- The patch is loaded earlier takes precedence in terms of entries loaded.
local GRAFT_NAME = {
    [GRAFT_TYPE.NEGOTIATION] = "UI.GRAFT_COLLECTION.SLOT_TYPE_NEGOTIATION",
    [GRAFT_TYPE.COMBAT] = "UI.GRAFT_COLLECTION.SLOT_TYPE_COMBAT",
    [GRAFT_TYPE.COIN] = "UI.GRAFT_COLLECTION.SLOT_TYPE_COIN",
    [GRAFT_TYPE.SOCIAL] = function(graft)
        return graft:GetDef().is_good and "UI.GRAFT_COLLECTION.SLOT_TYPE_SOCIAL_BOON" or "UI.GRAFT_COLLECTION.SLOT_TYPE_SOCIAL_BANE"
    end,
}

local PickGraftOption = Widget.PickGraftOption
local oldInitFunction = PickGraftOption.init

if not PickGraftOption.GRAFT_COLORS_MAP or not PickGraftOption.GRAFT_NAME_MAP then
    function PickGraftOption:init(graft)
        oldInitFunction(self, graft)
        local graftType = graft:GetType()
        local graftColor = graftType and self.GRAFT_COLORS_MAP[graftType] or UICOLOURS.FIGHT
        if type(graftColor) == "function" then
            graftColor = graftColor(graft)
        end
        -- Not the name of the graft, the type name
        local graftName = graftType and self.GRAFT_NAME_MAP[graftType]
        if type(graftName) == "function" then
            graftName = graftName(graft)
        end
        graftName = graftName and LOC(graftName) or LOC"UI.GRAFT_COLLECTION.SLOT_TYPE_NONE"
        self.bg:SetTintColour(graftColor)
        self.gradient:SetTintColour(graftColor)
        self.graft_frame:SetTintColour(graftColor)
        self.title:SetGlyphColour(graftColor)
        self.overlay:SetTintColour(graftColor)

        local testIcon = engine.asset.Texture("UI/ic_subcard_negotiation.tex")
        self.class_label.bg:SetTintColour(graftColor)
        self.class_label.icon:SetTintColour(graftColor)
        self.class_label.label:SetText(graftName)
        self.class_label.label:SetTintColour(graftColor)

        local rarity_color = MakeColourString( HexColour( CARD_RARITY_COLOURS[ self.graft:GetRarity() or CARD_RARITY.UNIQUE ] ) )
        local rarity_name = GetCardRarityString( self.graft:GetRarity() )
        local rarity_icon_string = GetCardRarityIconString( self.graft:GetRarity() )

        self.subtitle:SetText( string.upper( loc.format( LOC"UI.GRAFT_COLLECTION.SLOT_SUBTITLE", rarity_color, rarity_name, graftName, rarity_icon_string ) ) )
    end
end
PickGraftOption.GRAFT_COLORS_MAP = PickGraftOption.GRAFT_COLORS_MAP or GRAFT_COLORS
PickGraftOption.GRAFT_NAME_MAP = PickGraftOption.GRAFT_NAME_MAP or GRAFT_NAME
for id, value in pairs(GRAFT_COLORS) do
    PickGraftOption.GRAFT_COLORS_MAP[id] = PickGraftOption.GRAFT_COLORS_MAP[id] or GRAFT_COLORS[id]
end
for id, value in pairs(GRAFT_NAME) do
    PickGraftOption.GRAFT_NAME_MAP[id] = PickGraftOption.GRAFT_NAME_MAP[id] or GRAFT_NAME[id]
end
