DEFAULT_CHAT_FRAME:AddMessage("|cffa86cf1A |cffffc72cstraw|cffa86cf1 for every |cff85af67turtle|cffa86cf1? How generous!")
local frame = CreateFrame("Frame", "GoblinBrainwashingAddonFrame", UIParent)

-- SavedVariablesPerCharacter
GBHSpec = GBHSpec or {}
RGBSpec = RGBSpec or {} 

for i = 1, 4 do
RGBSpec[i] = RGBSpec[i] or {1, 0, 0} -- set default color
end

local textFrame = CreateFrame("Frame", "GoblinBrainwashingTextFrame", GossipFrame)
textFrame:SetWidth(133)
textFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
textFrame:SetBackdropColor(0, 0, 0, 0.7)
textFrame:SetPoint("TOPLEFT", GossipFrame, "RIGHT", -29, 65)
textFrame:Hide()

local helperButton = CreateFrame("Button", "ToggleTextFrameButton", GossipFrame, "UIPanelButtonTemplate")
helperButton:SetWidth(45)
helperButton:SetHeight(18)
helperButton:SetText("Helper")
helperButton:SetPoint("TOPLEFT", GossipFrame, "TOPRIGHT", -101, -22)
helperButton:Hide()

helperButton:SetScript("OnClick", function()
    if textFrame:IsShown() then
        textFrame:Hide()
    else
        textFrame:Show()
    end
end)

	-- update colour of index specRGBFrame/GBSpec
local function UpdatespecRGBFrameColour(index, r, g, b)
    RGBSpec[index] = {r, g, b} 
	local specRGBFrame = _G["specRGBFrame" .. index]
    local specColor = specRGBFrame.texture
	specColor:SetVertexColor(r, g, b)
end

	-- colorPicker
local function OpenColorPicker(button, index)
    ColorPickerFrame.func = nil -- clear previous specRGBFrame inndex

    local function ColorPickerCallback()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        UpdatespecRGBFrameColour(index, newR, newG, newB) -- update colour of specRGBFrame/RGBSpec
    end

    -- colorPicker setup
    ColorPickerFrame:SetColorRGB(unpack(RGBSpec[index]))
    ColorPickerFrame.previousValues = RGBSpec[index]
    ColorPickerFrame.func = function() ColorPickerCallback(nil) end
    ShowUIPanel(ColorPickerFrame)
end

	-- create base specEditBox and specRGBFrame
local function CreatespecEditBox(parent, index)
    local specEditBox = CreateFrame("EditBox", "specEditBox" .. index, parent, "InputBoxTemplate")
    specEditBox:SetWidth(100)
    specEditBox:SetHeight(30)
    specEditBox:SetAutoFocus(false)
    specEditBox:SetMaxLetters(16)
    specEditBox:SetPoint("TOP", parent, "TOP", -10, -38 * (index - 1) - 10)

    specRGBFrame = CreateFrame("Button", "specRGBFrame" .. index, parent)
    specRGBFrame:SetWidth(17)
    specRGBFrame:SetHeight(17)
    specRGBFrame:SetPoint("LEFT", specEditBox, "RIGHT", 5, 0)

    specRGBTexture = specRGBFrame:CreateTexture(nil, "BACKGROUND")
    specRGBTexture:SetAllPoints()
    specRGBTexture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    specRGBTexture:SetVertexColor(unpack(RGBSpec[index] or {0.5, 0.5, 0.5}))
    specRGBFrame.texture = specRGBTexture

    specRGBFrame:SetScript("OnClick", function()
        OpenColorPicker(specRGBFrame, index)
    end)

    specEditBox:SetScript("OnEditFocusLost", function()
        GBHSpec[index] = specEditBox:GetText()
    end)

    return specEditBox
end

	-- replace gossip text with specEditBox/GBHSpec text
local function UpdateGossipOptions()
    for i = 1, 4 do 
        local GBHSpecText = GBHSpec[i]
        if GBHSpecText then
			local gossipOptions = {GetGossipOptions()}
			local numOptions = table.getn(gossipOptions)
            for j = 1, numOptions do 
                local button = _G["GossipTitleButton" .. j]
                if button and button:GetText() then 
                    local text = button:GetText()
                    local startPos = string.find(text, "Activate%s" .. i .. "%l%l%sSpecialization")
                    if startPos then
                        HexRGB = string.format("%02x%02x%02x", math.floor(RGBSpec[i][1]*255), math.floor(RGBSpec[i][2]*255), math.floor(RGBSpec[i][3]*255))
                        local newText = string.gsub(text, "%d%l%l%sSpecialization", "|cFF000000|r|cff"..HexRGB .. GBHSpec[i] .. "|r Spec") 
                        button:SetText(newText)
                    end
                end
            end
        end
    end
end


	--events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("GOSSIP_CLOSED")

frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "GoblinBrainwashingHelper" then
    elseif event == "GOSSIP_SHOW" then		
		if GossipFrameNpcNameText:GetText() == "Goblin Brainwashing Device" then
			 helperButton:Show()
			local gossipOptions = {GetGossipOptions()}
            local activateCount = 0
			local numOptions = table.getn(gossipOptions)
			
			for i = 1, numOptions,2 do
				local optionText = gossipOptions[i]
				if string.find(optionText, "Activate ... Specialization") then
						activateCount = activateCount + 1
				end
			end
			
			for i = 1, activateCount do
                local specEditBox = _G["specEditBox" .. i] or CreatespecEditBox(textFrame, i)
                specEditBox:SetText(GBHSpec[i] or "")
                specEditBox:Show()
            end

            for i = activateCount + 1, 4 do
                local specEditBox = _G["specEditBox" .. i]
                if specEditBox then
                    specEditBox:Hide()
                end
            end
            local newHeight = activateCount * 38
            textFrame:SetHeight(newHeight)
            UpdateGossipOptions()
        else
        end

    elseif event == "GOSSIP_CLOSED" then
        helperButton:Hide()
        textFrame:Hide()
    end
end)