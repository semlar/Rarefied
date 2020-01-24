local f, loop, recent = CreateFrame('frame'), 0, {}
f:SetAllPoints()
f:SetAlpha(0)
f:SetFrameStrata('FULLSCREEN_DIALOG')

local tx = f:CreateTexture()
tx:SetBlendMode('ADD')
tx:SetAllPoints()
tx:SetTexture([[interface\fullscreentextures\lowhealth]])

local fade = f:CreateAnimationGroup()
fade:SetToFinalAlpha(false)

local alpha = fade:CreateAnimation('Alpha')
alpha:SetFromAlpha(0)
alpha:SetToAlpha(1)
alpha:SetDuration(0.5)
--alpha:SetEndDelay(0.25)

fade:SetLooping('BOUNCE')
fade:SetScript('OnLoop', function()
	loop = loop + 1
	if loop >= 5 then
		loop = 0
		fade:Finish()
	end
end)

local x1, x2, y1, y2 = GetObjectIconTextureCoords(4733)
local MessageString = format('|Tinterface/minimap/objecticonsatlas.blp:16:16:0:0:256:256:%f:%f:%f:%f|t%%s detected at %%s!', x1 * 256, x2 * 256, y1 * 256, y2 * 256)



local pins = {}
local function RedrawPins(self)
	local uiMapID = self:GetMapID()
	for k,v in pairs(pins) do
		self:RemovePin(v)
		pins[k] = nil
	end
	if uiMapID then
		for _, vignetteID in pairs(C_VignetteInfo.GetVignettes()) do
			local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteID)
			local position = C_VignetteInfo.GetVignettePosition(vignetteID, uiMapID)
			--local pin = self:GetMap():AcquirePin("FlightMap_FlightPointPinTemplate", playAnim);
			local pin = self:AcquirePin("VignettePinTemplate", vignetteID, vignetteInfo)
			--pins[vignetteID] = pin
			tinsert(pins, pin)
			pin:Show()
		end
	end
end

hooksecurefunc(WorldMapFrame, 'OnMapChanged', RedrawPins)
WorldMapFrame:HookScript('OnShow', RedrawPins)



local ActiveVignettes = {}

f:SetScript('OnEvent', function(_, event, id, onMap)
	local currentVignettes = {}
	for _, vignetteID in pairs(C_VignetteInfo.GetVignettes()) do
		if not ActiveVignettes[vignetteID] then
			-- new vignette
			local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteID)
			if vignetteInfo then
				ActiveVignettes[vignetteID] = vignetteInfo
				local name = vignetteInfo.name
				
				if vignetteInfo.vignetteID ~= 637 then -- garrison swag?
					local now = GetTime()
					if not name then name = id end
					if recent[name] and now - recent[name] < 300 then recent[name] = now return end -- ignore recently seen
					local msg = format(MessageString, name or 'Rare', date('%I:%M', time()))
					RaidWarningFrame_OnEvent(RaidWarningFrame, 'CHAT_MSG_RAID_WARNING', msg)
					DEFAULT_CHAT_FRAME:AddMessage(msg)
					recent[name] = now
					--PlaySoundFile([[sound\event sounds\event_wardrum_ogre.ogg]], 'Master')
					--PlaySoundFile([[sound\events\scourge_horn.ogg]], 'Master')
					fade:Play()
				end
			end
		end
		currentVignettes[vignetteID] = true
	end
	
	if event == 'VIGNETTE_MINIMAP_UPDATED' then
		currentVignettes[id] = onMap
	end
	for vignetteID in pairs(ActiveVignettes) do
		if not currentVignettes[vignetteID] then
			-- remove vignette
			ActiveVignettes[vignetteID] = nil
		end
	end
	RedrawPins(WorldMapFrame)
end)


f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:RegisterEvent('VIGNETTE_MINIMAP_UPDATED') -- doesn't fire on a reload
f:RegisterEvent('VIGNETTES_UPDATED') -- fires even outside of visible vignette range? just keeps firing every half second or so when there's a vignette nearby