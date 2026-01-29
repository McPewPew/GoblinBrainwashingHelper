DEFAULT_CHAT_FRAME:AddMessage("|cffa86cf1A |cffffc72cstraw|cffa86cf1 for every |cff85af67turtle|cffa86cf1? How generous!")
local frame = CreateFrame("Frame", "GoblinBrainwashingAddonFrame", UIParent)

local helperChatFrame_OnEvent = nil
local numberOfSpecs = 0
local helperFrame
local helperButton
local editBoxTable = {}
local specSwatchTable = {}
local numOptions
local gossipTitleButtonPoint, gossipTitleButtonRelativeTo, gossipTitleButtonRelativePoint, gossipTitleButtonX, gossipTitleButtonY

--'hides' "Activate ??? Specialization" and replaces it with custom text
local function hideAndReplaceSpec(gossipButton, specNameAndColor, originalGossipText)
	--save original spec text
    local originalSpecText = gossipButton:GetFontString()	

    --create new gossip text string
	if not gossipButton.textPrefix then
		-- save original text color to restore it later
		local r, g, b, a = originalSpecText:GetTextColor()
		gossipButton.textColor = { r, g, b, a }
	
		local font, size = originalSpecText:GetFont()
	
		--prefix "Activate"
		gossipButton.textPrefix = gossipButton:CreateFontString(nil, "OVERLAY", "DialogButtonNormalText")
		gossipButton.textPrefix:SetFont(font, size)
		gossipButton.textPrefix:SetTextColor(r, g, b, a)
	
		--our colored spec text
		gossipButton.textColoredSpec = gossipButton:CreateFontString(nil, "OVERLAY", "DialogButtonNormalText")
		gossipButton.textColoredSpec:SetFont(font, size, "THICKOUTLINE")
	
		--suffix " Spec"..(xx/xx/xx)
		gossipButton.textSuffix = gossipButton:CreateFontString(nil, "OVERLAY", "DialogButtonNormalText")
		gossipButton.textSuffix:SetFont(font, size)
		gossipButton.textSuffix:SetTextColor(r, g, b, a)

	end

    --grab spec (xx/xx/xx)
    local specNumbers = ""
    local specNumbersStart, specNumbersEnd = string.find(originalGossipText, "%(%d+/%d+/%d+%)")
    if specNumbersStart and specNumbersEnd then specNumbers = " " .. string.sub(originalGossipText, specNumbersStart, specNumbersEnd) end

    --"hide" original text by setting its alpha to zero
    originalSpecText:SetTextColor(0, 0, 0, 0)
    
	--set new gossip text
    gossipButton.textPrefix:SetText("Activate ")
    gossipButton.textColoredSpec:SetText(specNameAndColor.name)
    gossipButton.textColoredSpec:SetTextColor(specNameAndColor.color[1], specNameAndColor.color[2], specNameAndColor.color[3])
    gossipButton.textSuffix:SetText(" Spec" .. specNumbers)
    --construct new gossip text
    gossipButton.textPrefix:SetPoint("LEFT", originalSpecText, "LEFT")
    gossipButton.textColoredSpec:SetPoint("LEFT", gossipButton.textPrefix, "RIGHT")
    gossipButton.textSuffix:SetPoint("LEFT", gossipButton.textColoredSpec, "RIGHT")
	--show new gossip text
    gossipButton.textPrefix:Show(); 
	gossipButton.textColoredSpec:Show(); 
	gossipButton.textSuffix:Show()
end

local function resetGossipText(gossipButton)
    --check it was changed
    if gossipButton.textColor then
        local rgba = gossipButton.textColor
        gossipButton:GetFontString():SetTextColor(rgba[1], rgba[2], rgba[3], rgba[4])
    end

    --only hide if we've replaced it
    if gossipButton.textPrefix then
        gossipButton.textPrefix:Hide()
        gossipButton.textColoredSpec:Hide()
        gossipButton.textSuffix:Hide()
    end
end

local function updateGossipOptions()
    for j = 1, numOptions do
        local gossipButton = getglobal("GossipTitleButton" .. j)
        if gossipButton then
            local originalGossipText = gossipButton:GetText()

            if gossipButton.textPrefix then
                resetGossipText(gossipButton)
            end

            if originalGossipText then
                local _, _, specNum = string.find(originalGossipText, "Activate%s(%d)%l%l%sSpecialization")
                specNum = tonumber(specNum)

                if specNum then
                    local specNameAndColor = helperNameAndColor[specNum]
                    if specNameAndColor and specNameAndColor.name ~= "" then
                        hideAndReplaceSpec(gossipButton, specNameAndColor, originalGossipText)
                    end
                end
            end
        end
    end
end

local function openColorPicker(swatch, index)
    -- clear ColorPickerFrame values from previous use
    ColorPickerFrame.func = nil
    ColorPickerFrame.cancelFunc = nil
	
	--load color from swatch to picker
    local existingColor = {unpack(helperNameAndColor[index].color)}
    ColorPickerFrame.previousValues = existingColor
    ColorPickerFrame:SetColorRGB(unpack(existingColor))
	
    --pick new spec name and swatch color
    ColorPickerFrame.func = function()
        local r,g,b = ColorPickerFrame:GetColorRGB()
        
		--set new color and set swatch
		helperNameAndColor[index].color = {r,g,b}
        swatch.texture:SetVertexColor(r,g,b)
        
        --live updae spec name color
        updateGossipOptions()
    end

    --cancel and revert to existingColor
    ColorPickerFrame.cancelFunc = function()
        local r,g,b = existingColor[1], existingColor[2], existingColor[3]
        helperNameAndColor[index].color = {r,g,b}
        swatch.texture:SetVertexColor(r,g,b)
        
        --revert the spec name to saved color
        updateGossipOptions()
    end
    
    ShowUIPanel(ColorPickerFrame)
end

--create specEditBox and specSwatch
local function createSpecEditBox(index)
	--editboxes for spec names
	local specEditBox = CreateFrame("EditBox", "specEditBox" .. index, helperFrame, "InputBoxTemplate")
	specEditBox:SetWidth(100)
	specEditBox:SetHeight(30)
	specEditBox:SetAutoFocus(false)
	specEditBox:SetMaxLetters(16)
	specEditBox:SetPoint("TOPLEFT", helperFrame, "TOPLEFT", 11, -23 * (index - 1))
	
	specEditBox:SetScript("OnTextChanged", function()
		helperNameAndColor[index].name = specEditBox:GetText()
		updateGossipOptions() -- live updates
	end)
	
	specEditBox:SetScript("OnEnterPressed", function()
		specEditBox:ClearFocus()
	end)
	
	specEditBox:SetScript("OnEscapePressed", function()
		--revert to saved text
		specEditBox:SetText(helperNameAndColor[index].name or "")
		specEditBox:ClearFocus()
	end)

	--color swatch
	local specSwatch = CreateFrame("Button", nil, helperFrame)
	specSwatch:SetWidth(16)
	specSwatch:SetHeight(16)
	specSwatch:SetPoint("LEFT", specEditBox, "RIGHT", 5, -1)
	specSwatch:SetHighlightTexture("Interface\\Buttons\\CheckButtonHilight")
	specSwatch:SetScript("OnClick", function()
		openColorPicker(specSwatch, index)
	end)
	--swatch texture
	specSwatch.texture = specSwatch:CreateTexture(nil, "BACKGROUND")
	specSwatch.texture:SetAllPoints()
	specSwatch.texture:SetTexture("Interface\\Buttons\\WHITE8X8")
	--set to saved colors
	specSwatch.texture:SetVertexColor(unpack(helperNameAndColor[index].color))

	--table of created boxes
	editBoxTable[index] = specEditBox
	specSwatchTable[index] = specSwatch

	return specEditBox
end

--creat/show Helper frame
local function showOrCreateHelper()
    if not helperFrame then
        helperFrame = CreateFrame("Frame", "GoblinBrainwashingHelper", GossipFrame)
        helperFrame:SetWidth(140)
        helperFrame:SetPoint("TOPLEFT", GossipFrame, "RIGHT", -29, 38)
		helperFrame:SetBackdropColor(0, 0, 0, 0.7)
        helperFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
		helperFrame:SetBackdropBorderColor(0.85, 0.85, 0.85, 1)
    end

    --set hight of frame based on number of specs
    local newHeight = 8 + (numberOfSpecs * 23)
    helperFrame:SetHeight(newHeight)

    --editboxes and swatches
    for i = 1, numberOfSpecs do
        local specEditBox = editBoxTable[i] or createSpecEditBox(i)        
        specEditBox:SetText(helperNameAndColor[i].name or "")
        specEditBox:Show()
		
        if specSwatchTable[i] then
            specSwatchTable[i]:Show()
            specSwatchTable[i].texture:SetVertexColor(unpack(helperNameAndColor[i].color))    
        end
    end
    helperFrame:Show()
end

--button to toggle addon frame
local function showOrCreateHelperButton()
    if not helperButton then
        helperButton = CreateFrame("Button", "ToggleHelper", GossipFrame, "UIPanelButtonTemplate")
        helperButton:SetWidth(45)
        helperButton:SetHeight(18)
        helperButton:SetText("Helper")
        helperButton:SetPoint("TOPLEFT", GossipFrame, "TOPRIGHT", -101, -22)
        
        helperButton:SetScript("OnClick", function()
            --toggle Helper
            if helperFrame and helperFrame:IsVisible() then
                helperFrame:Hide()
            else
                showOrCreateHelper()
            end
        end)
    end
    helperButton:Show()
end

--suppress respec spam
local function respecSpamSuppression()
	if helperChatFrame_OnEvent then
		return
	end
	
	helperChatFrame_OnEvent = ChatFrame_OnEvent
    
    ChatFrame_OnEvent = function(event)
        if event == "CHAT_MSG_SYSTEM" and arg1 then
            if string.find(arg1, "^You have learned a new spell:") or 
               string.find(arg1, "^You have learned a new ability:") or 
               string.find(arg1, "^You have unlearned") then
                return true 
            end
        end
        helperChatFrame_OnEvent(event)
    end
end

-- events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("GOSSIP_CLOSED")

frame:SetScript("OnEvent", function()
	if event == "GOSSIP_SHOW" then
		if GossipFrameNpcNameText and GossipFrameNpcNameText:GetText() == "Goblin Brainwashing Device" then	
			--slight move GossipTitleButtons to 'improve' layout
			gossipTitleButtonPoint, gossipTitleButtonRelativeTo, gossipTitleButtonRelativePoint, gossipTitleButtonX, gossipTitleButtonY = GossipTitleButton1:GetPoint() 
			GossipTitleButton1:ClearAllPoints()
			GossipTitleButton1:SetPoint(gossipTitleButtonPoint, gossipTitleButtonRelativeTo, gossipTitleButtonRelativePoint, 0, -2)

			numberOfSpecs = 0
			
			local gossipOptions = { GetGossipOptions() }
			numOptions = table.getn(gossipOptions) / 2 -- real number of options
			
			--count "Activate ... Specialization" options
			numberOfSpecs = 0
			for j = 1, numOptions do
				local optionText = gossipOptions[j * 2 - 1]   -- text for option j
				if optionText and string.find(optionText, "Activate%s%d%a%a%sSpecialization") then
					numberOfSpecs = numberOfSpecs + 1
				end
			end
			
			--use/set helperNameAndColor SavedVariable for numberOfSpecs specs
			if not helperNameAndColor then
				--check for savedvariables from previous version and map to helperNameAndColor
				if GBHSpec then
					helperNameAndColor = {}
					for i = 1, 4 do
						helperNameAndColor[i] = {
							name  = GBHSpec[i] or "",
							color = {RGBSpec[i][1], RGBSpec[i][2], RGBSpec[i][3]},
						}
					end
				else
					helperNameAndColor = {}
				end
			end
			
			for i = 1, numberOfSpecs do
				if not helperNameAndColor[i] then
					helperNameAndColor[i] = {
						name  = "",
						color = { 1, 0, 0 },
					}
				end
			end
			
			showOrCreateHelperButton()
			updateGossipOptions()
			respecSpamSuppression()
		end
	elseif event == "GOSSIP_CLOSED" then
		if GossipFrameNpcNameText and GossipFrameNpcNameText:GetText() == "Goblin Brainwashing Device" then	
			-- restore visuals
			for j = 1, numOptions do
				local gossipButton = getglobal("GossipTitleButton" .. j)
				if not gossipButton then break end
				resetGossipText(gossipButton)
			end
			--revert movement of GossipTitleButtons
			GossipTitleButton1:ClearAllPoints()
			GossipTitleButton1:SetPoint(gossipTitleButtonPoint, gossipTitleButtonRelativeTo, gossipTitleButtonRelativePoint, gossipTitleButtonX, gossipTitleButtonY)
			
			if helperFrame then helperFrame:Hide() end
			--remove suppression of learned/unlearned spam
			if helperChatFrame_OnEvent then
				ChatFrame_OnEvent = helperChatFrame_OnEvent
				helperChatFrame_OnEvent = nil
			end
		end
	end
end)