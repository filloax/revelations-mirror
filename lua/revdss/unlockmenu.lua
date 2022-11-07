local unlockOrder = {"ICETRAY", "WILLO", "BANDAGE_BABY", "MIRROR_BOMBS", "GLACIER_CHAMPIONS", "TOMB_CHAMPIONS", "MAX_HORN", "PENANCE", "OPHANIM", "LIL_MICHAEL", "PILGRIMS_WARD", "HEAVENLY_BELL", "BROKEN_OAR", "DEATH_MASK", "WANDERING_SOUL", "FERRYMANS_TOLL", "GHASTLY_FLAME"}
local unlockSprites = {}
local lastUnlockState = {}

local function GenerateUnlockMenu(item)
    local unlockButtons = {}
    for name, unlock in pairs(REVEL.UNLOCKABLES) do
        if unlock.menuName and unlock.menuLocked then
            local substr
            if revel.data.unlockValues[name] then
                substr = {str = unlock.menuLocked, alpha = 1}
            else
                substr = {str = "locked!", alpha = 0.5}
            end

            local index
            for i, unlockName in ipairs(unlockOrder) do
                if name == unlockName then
                    index = i
                end
            end

            if index then
                if not unlockSprites[name] or lastUnlockState[name] ~= revel.data.unlockValues[name] then
                    local sprite = unlockSprites[name] or Sprite()
                    sprite:Load("gfx/ui/achievement/achievement_icon.anm2", true)
                    sprite:Play("Idle")
                    if (unlock.item or unlock.menuIcon) and revel.data.unlockValues[name] then
                        if unlock.menuIcon then
                            if type(unlock.menuIcon) == "table" then
                                sprite:ReplaceSpritesheet(0, unlock.menuIcon.sprite)
                            else
                                sprite:ReplaceSpritesheet(0, unlock.menuIcon)
                            end
                        else
                          if unlock.isTrinket then
                            sprite:ReplaceSpritesheet(0, REVEL.config:GetTrinket(unlock.item).GfxFileName)
                          else
                            sprite:ReplaceSpritesheet(0, REVEL.config:GetCollectible(unlock.item).GfxFileName)
                          end
                        end
                    else
                        sprite:ReplaceSpritesheet(0, "gfx/items/collectibles/questionmark.png")
                    end
                    sprite:LoadGraphics()
                    unlockSprites[name] = sprite
					lastUnlockState[name] = revel.data.unlockValues[name]
                end

                local scaleX, scaleY, width, height = 3, 3, 32, 32
                if unlock.menuIcon and type(unlock.menuIcon) == "table" and revel.data.unlockValues[name] then
                    scaleX = unlock.menuIcon.scaleX or scaleX
                    scaleY = unlock.menuIcon.scaleY or scaleY
                    width = unlock.menuIcon.width or width
                    height = unlock.menuIcon.height or height
                end

                unlockButtons[index] = {str = unlock.menuName, substr = substr, unlockName = name .. "!",
                    tooltip = {spr = {sprite = unlockSprites[name], shadow = true, invisible = false, float = {3, 2.5}, scale = Vector(scaleX, scaleY), width = width, height = height, center = true}},
                    func = function() if not REVEL.GetShowingAchievement() and REVEL.IsAchievementUnlocked(name) then
                        REVEL.AnimateAchievement("gfx/ui/achievement/"..unlock.img, SoundEffect.SOUND_BOOK_PAGE_TURN_12, nil, -1)
                      end
                    end
                }
            end
        end
    end

    return unlockButtons
end

return {
    GenerateUnlockMenu = GenerateUnlockMenu
}