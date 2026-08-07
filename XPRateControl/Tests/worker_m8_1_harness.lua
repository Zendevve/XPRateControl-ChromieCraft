-- Tests/worker_m8_1_harness.lua
-- Integration test harness for Milestone 8: Joyous Journeys effective-rate display
-- (JJ-aware rate math, hero/tag/badge UI, JJ checkbox, /xp status, automation messages)

local XPRate = {}
local addonName = "XPRateControl"

-- Mock WoW Environment
local printedMessages = {}
local showToastCalls = {}
local showTooltipCalls = {}
local hideTooltipCalls = {}
local applyRateCalls = {}
local sentChatMessages = {}
local allFontStrings = {}

DEFAULT_CHAT_FRAME = {
  AddMessage = function(self, msg)
    table.insert(printedMessages, msg)
  end
}
SlashCmdList = {}
UISpecialFrames = {}

local registeredEvents = {}
local createdFrames = {}

function CreateFrame(frameType, name, parent, template)
  local frame = {
    name = name,
    frameType = frameType,
    parent = parent,
    template = template,
    events = {},
    scripts = {},
    children = {},
    textures = {},
    fontstrings = {},
    shown = false,
    checked = false,
    width = 0,
    height = 0,
    point = nil,
    strata = "MEDIUM",
    level = 1,
    text = "",
    value = 1.0,
    backdrop = nil,

    RegisterEvent = function(self, evt)
      self.events[evt] = true
      registeredEvents[evt] = true
    end,
    SetScript = function(self, scriptType, fn)
      self.scripts[scriptType] = fn
    end,
    GetScript = function(self, scriptType)
      return self.scripts[scriptType]
    end,
    CreateFontString = function(self, n, layer, inherits)
      local fs = {
        name = n, text = "", r=1, g=1, b=1, a=1, shown = true,
        SetText = function(s, t) s.text = tostring(t) end,
        GetText = function(s) return s.text end,
        SetTextColor = function(s, r, g, b, a) s.r=r; s.g=g; s.b=b; s.a=a or 1 end,
        SetPoint = function() end,
        SetJustifyH = function() end,
        SetJustifyV = function() end,
        SetAllPoints = function() end,
        Show = function(s) s.shown = true end,
        Hide = function(s) s.shown = false end,
        IsShown = function(s) return s.shown end,
        SetAlpha = function(s, a) s.a = a end,
        GetAlpha = function(s) return s.a end,
        GetStringWidth = function(s) return 10 end,
        GetStringHeight = function(s) return 10 end,
      }
      table.insert(self.fontstrings, fs)
      table.insert(allFontStrings, fs)
      if n then _G[n] = fs end
      return fs
    end,
    CreateTexture = function(self, n, layer)
      local tex = {
        name = n, texture = "", r=1, g=1, b=1, a=1,
        SetSize = function() end,
        SetPoint = function() end,
        SetTexture = function(s, t) s.texture = t end,
        SetVertexColor = function(s, r, g, b, a) s.r=r; s.g=g; s.b=b; s.a=a or 1 end,
        SetAllPoints = function() end,
        SetGradientAlpha = function() end,
        SetBlendMode = function() end,
        SetHeight = function() end,
        SetAlpha = function(s, a) s.a = a end,
        SetDesaturated = function(s, v) s.desaturated = v and true or false end,
        SetTexCoord = function() end,
      }
      table.insert(self.textures, tex)
      if n then _G[n] = tex end
      return tex
    end,
    SetSize = function(self, w, h) self.width = w; self.height = h end,
    SetWidth = function(self, w) self.width = w end,
    SetHeight = function(self, h) self.height = h end,
    GetSize = function(self) return self.width, self.height end,
    SetPoint = function(self, pt, relTo, relPt, x, y)
      self.point = { pt = pt, relTo = relTo, relPt = relPt, x = x, y = y }
    end,
    GetPoint = function(self)
      if self.point then
        return self.point.pt, self.point.relTo, self.point.relPt, self.point.x, self.point.y
      end
      return "CENTER", nil, "CENTER", 0, 0
    end,
    ClearAllPoints = function(self) self.point = nil end,
    SetBackdrop = function(self, bd) self.backdrop = bd end,
    SetBackdropColor = function(self, r, g, b, a) self.bgColor = {r, g, b, a} end,
    SetBackdropBorderColor = function(self, r, g, b, a) self.edgeColor = {r, g, b, a} end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
    IsShown = function(self) return self.shown end,
    SetAlpha = function(self, a) self.alpha = a end,
    GetAlpha = function(self) return self.alpha or 1 end,
    SetShown = function(self, val) self.shown = val and true or false end,
    Disable = function(self) self.disabled = true end,
    Enable = function(self) self.disabled = false end,
    SetChecked = function(self, val) self.checked = val and true or false end,
    GetChecked = function(self) return self.checked end,
    SetFrameStrata = function(self, st) self.strata = st end,
    SetFrameLevel = function(self, lvl) self.level = lvl end,
    GetFrameLevel = function(self) return self.level end,
    SetAllPoints = function() end,
    SetAutoFocus = function() end,
    SetFontObject = function() end,
    SetJustifyH = function() end,
    SetMaxLetters = function() end,
    HasFocus = function() return false end,
    ClearFocus = function() end,
    SetFocus = function() end,
    HighlightText = function() end,
    GetText = function(self) return self.text end,
    SetText = function(self, t) self.text = tostring(t) end,
    SetMinMaxValues = function() end,
    SetValueStep = function() end,
    SetOrientation = function() end,
    SetThumbTexture = function() end,
    GetValue = function(self) return self.value end,
    SetValue = function(self, v) self.value = v end,
    EnableMouseWheel = function() end,
    EnableMouse = function() end,
    SetMovable = function() end,
    SetClampedToScreen = function() end,
    RegisterForDrag = function() end,
    RegisterForClicks = function() end,
    StartMoving = function() end,
    StopMovingOrSizing = function() end,
    SetHighlightTexture = function() end,
    LockHighlight = function() end,
    UnlockHighlight = function() end,
    SetScale = function() end,
    GetCenter = function() return 0, 0 end,
    Click = function(self)
      local onClick = self:GetScript("OnClick")
      if onClick then onClick(self) end
    end
  }
  table.insert(createdFrames, frame)
  if parent and parent.children then table.insert(parent.children, frame) end
  if name then _G[name] = frame end
  return frame
end

UIParent = CreateFrame("Frame", "UIParent")
Minimap = CreateFrame("Frame", "Minimap")
Minimap.GetCenter = function() return 0, 0 end
Minimap.GetEffectiveScale = function() return 1 end
Minimap.GetWidth = function() return 200 end
Minimap.GetHeight = function() return 200 end

-- Global API stubs
strtrim = function(s) return s and s:match("^%s*(.-)%s*$") or "" end
tinsert = table.insert
UnitLevel = function(unit) return 70 end
UnitGUID = function(unit) return "Player-1" end
UnitExists = function(unit) return false end
UnitCanAttack = function(unit, other) return false end
GetNumPartyMembers = function() return 0 end
GetNumRaidMembers = function() return 0 end
IsInInstance = function() return false, "none" end
GetRealZoneText = function() return "Elwynn Forest" end
GetQuestDifficultyColor = function(level) return {r=1, g=1, b=1} end
GetXPExhaustion = function() return 0 end
GetRestState = function() return 2 end
GetMinimapShape = function() return "ROUND" end
GetCursorPosition = function() return 0, 0 end
EasyMenu = function() end
SendChatMessage = function(msg, chatType, language, target)
  table.insert(sentChatMessages, msg)
end

GameTooltip = {
  SetOwner = function() end,
  SetText = function(self, txt)
    table.insert(showTooltipCalls, txt)
  end,
  Show = function() end,
  Hide = function()
    table.insert(hideTooltipCalls, true)
  end
}

-- Load Addon Source Files in strict TOC order
XPRateControlDB = nil
local configChunk = assert(loadfile("Core/Config.lua"))
configChunk(addonName, XPRate)
XPRate.InitDB()

local uiHelpersChunk = assert(loadfile("Core/UIHelpers.lua"))
uiHelpersChunk(addonName, XPRate)

-- Track ShowToast calls (before Network/Automation/UI capture their locals)
local originalShowToast = XPRate.ShowToast
XPRate.ShowToast = function(text, isError)
  table.insert(showToastCalls, text)
  if originalShowToast then return originalShowToast(text, isError) end
end

local networkChunk = assert(loadfile("Core/Network.lua"))
networkChunk(addonName, XPRate)

-- Track ApplyRate calls (before Automation captures its local)
local originalApplyRate = XPRate.ApplyRate
XPRate.ApplyRate = function(rate, silent)
  table.insert(applyRateCalls, { rate = rate, silent = silent })
  if originalApplyRate then return originalApplyRate(rate, silent) end
end

local autoChunk = assert(loadfile("Engine/Automation.lua"))
autoChunk(addonName, XPRate)

local mainFrameChunk = assert(loadfile("UI/MainFrame.lua"))
mainFrameChunk(addonName, XPRate)

local minimapButtonChunk = assert(loadfile("UI/MinimapButton.lua"))
minimapButtonChunk(addonName, XPRate)

local tabRatesChunk = assert(loadfile("UI/TabRates.lua"))
tabRatesChunk(addonName, XPRate)

local tabAutomationChunk = assert(loadfile("UI/TabAutomation.lua"))
tabAutomationChunk(addonName, XPRate)

local tabBuffsChunk = assert(loadfile("UI/TabBuffs.lua"))
tabBuffsChunk(addonName, XPRate)

local tabSettingsChunk = assert(loadfile("UI/TabSettings.lua"))
tabSettingsChunk(addonName, XPRate)

local initChunk = assert(loadfile("Init.lua"))
initChunk(addonName, XPRate)

-- Test Engine
local testsPassed = 0
local testsFailed = 0
local totalAssertions = 0

local function assert_true(val, msg)
  totalAssertions = totalAssertions + 1
  if not val then
    error("Assertion failed: " .. (msg or "expected true, got false/nil"))
  end
end

local function assert_equal(expected, actual, msg)
  totalAssertions = totalAssertions + 1
  if expected ~= actual then
    error(string.format("Assertion failed: %s (expected %s, got %s)", msg or "", tostring(expected), tostring(actual)))
  end
end

local function test(name, fn)
  local pass, err = pcall(fn)
  if pass then
    testsPassed = testsPassed + 1
    print("[PASS] " .. name)
  else
    testsFailed = testsFailed + 1
    print("[FAIL] " .. name .. " -> " .. tostring(err))
  end
end

local function resetLogs()
  printedMessages = {}
  showToastCalls = {}
  showTooltipCalls = {}
  hideTooltipCalls = {}
  applyRateCalls = {}
  sentChatMessages = {}
end

local function stripColorCodes(s)
  s = s:gsub("|c[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]", "")
  s = s:gsub("|r", "")
  return s
end

local function hasPrintedMessage(substring)
  for _, m in ipairs(printedMessages) do
    if m:find(substring, 1, true) then return true end
  end
  return false
end

local function hasPrintedMessageClean(substring)
  for _, m in ipairs(printedMessages) do
    if stripColorCodes(m):find(substring, 1, true) then return true end
  end
  return false
end

local function hasToast(substring)
  for _, t in ipairs(showToastCalls) do
    if t:find(substring, 1, true) then return true end
  end
  return false
end

print("==================================================")
print("  XPRateControl M8 Test Harness (worker_m8_1)")
print("  Joyous Journeys Effective-Rate Display")
print("==================================================")

-- 0. Init smoke test: event frame stores OnEvent; ADDON_LOADED syncs UI
test("0.1 ADDON_LOADED initializes JJ UI from DB", function()
  local initFrame = _G["XPRateEventFrame"]
  assert_true(initFrame ~= nil, "XPRateEventFrame exists")
  assert_true(type(initFrame.scripts.OnEvent) == "function", "XPRateEventFrame stores OnEvent handler")
  initFrame.scripts.OnEvent(initFrame, "ADDON_LOADED", addonName)
  assert_equal(true, XPRate.jjCheckbox:GetChecked(), "JJ checkbox synced to db.jjEnabled=true")
end)

-- 1. IsJJEnabled
test("1.1 IsJJEnabled reflects DB state", function()
  local fullDB = XPRateControlDB
  XPRateControlDB = nil
  assert_equal(false, XPRate.IsJJEnabled(), "IsJJEnabled false with nil DB")
  XPRateControlDB = { jjEnabled = true }
  assert_equal(true, XPRate.IsJJEnabled(), "IsJJEnabled true when jjEnabled=true")
  XPRateControlDB = { jjEnabled = false }
  assert_equal(false, XPRate.IsJJEnabled(), "IsJJEnabled false when jjEnabled=false")
  XPRateControlDB = fullDB
  assert_equal(true, XPRate.IsJJEnabled(), "full DB restored with jjEnabled default true")
end)

-- 2. EffectiveRate
test("1.2 EffectiveRate snaps to canonical base x1.5 only when JJ enabled", function()
  local fullDB = XPRateControlDB
  XPRateControlDB = { jjEnabled = false }
  assert_equal(2.0, XPRate.EffectiveRate(2.0), "2.0 stays 2.0 without JJ")
  assert_equal(1.5, XPRate.EffectiveRate(1.5), "1.5 stays 1.5 without JJ")
  XPRateControlDB = { jjEnabled = true }
  assert_equal(3.0, XPRate.EffectiveRate(2.0), "2.0 x 1.5 = 3.0 with JJ")
  assert_equal(3.0, XPRate.EffectiveRate(1.5), "1.5 snaps to base 2 -> 3.0 with JJ (nothing between 2 and 3)")
  assert_equal(1.5, XPRate.EffectiveRate(1.0), "1.0 x 1.5 = 1.5 with JJ")
  assert_equal(1.5, XPRate.EffectiveRate(0.5), "0.5 snaps to base 1 -> 1.5 with JJ")
  assert_equal(0, XPRate.EffectiveRate(0), "0 stays 0 with JJ")
  XPRateControlDB = fullDB
end)

-- 3. RateLabel
test("1.3 RateLabel tags OFF/Blizzlike/Maximum", function()
  assert_equal("OFF", XPRate.RateLabel(0), "RateLabel(0) is OFF")
  assert_equal("Blizzlike", XPRate.RateLabel(1), "RateLabel(1) is Blizzlike")
  assert_equal("Maximum", XPRate.RateLabel(2), "RateLabel(2) is Maximum")
  assert_equal("Maximum", XPRate.RateLabel(3), "RateLabel(3) is Maximum")
  assert_equal("", XPRate.RateLabel(1.5), "RateLabel(1.5) is empty")
end)

-- 4. ApplyRate with JJ enabled
test("1.4 ApplyRate(2.0) with JJ: chat, toast, db, lastAppliedRate", function()
  resetLogs()
  XPRateControlDB.jjEnabled = true
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = true
  XPRate.ApplyRate(2.0)

  assert_equal(".w r 2.00", sentChatMessages[#sentChatMessages], "last sent chat command is '.w r 2.00' (command space preserved)")
  assert_true(hasPrintedMessage("XP rate set to 2.00x (3.00x with Joyous Journeys)"), "printed message contains exact JJ parenthetical")
  assert_true(hasToast("Sent 2.00x [OK]"), "toast contains 'Sent 2.00x [OK]'")
  assert_equal(2.0, XPRateControlDB.lastRate, "db.lastRate is 2.0")
  assert_equal(2.0, XPRate.lastAppliedRate, "XPRate.lastAppliedRate is 2.0")
end)

-- 5. ApplyRate with JJ disabled
test("1.5 ApplyRate(2.0) without JJ: no parenthetical", function()
  resetLogs()
  XPRateControlDB.jjEnabled = false
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = true
  XPRate.ApplyRate(2.0)

  assert_true(hasPrintedMessage("XP rate set to 2.00x"), "printed message contains set-rate text")
  assert_equal(false, hasPrintedMessage("with Joyous Journeys"), "no JJ parenthetical when JJ disabled")
  assert_true(hasToast("Sent 2.00x [OK]"), "toast unchanged without JJ")
end)

-- 6. UpdateUIFromValue with JJ enabled
test("1.6 UpdateUIFromValue(2.0) with JJ: hero 3.00x, tag MAX, badge shown", function()
  resetLogs()
  XPRateControlDB.jjEnabled = true
  XPRate.UpdateUIFromValue(2.0, nil)

  local hero = _G["XPRateValueTextWidget"]
  assert_true(hero ~= nil, "hero fontstring XPRateValueTextWidget exists")
  assert_equal("3.00x", hero:GetText(), "hero text shows effective rate 3.00x")

  local tagFs = nil
  for _, fs in ipairs(allFontStrings) do
    if fs:GetText() == "MAX" then tagFs = fs break end
  end
  assert_true(tagFs ~= nil, "tag chip fontstring found (text MAX)")
  assert_equal("MAX", tagFs:GetText(), "tag chip shows MAX for effective 3.00x")

  assert_true(XPRate.jjBadge:IsShown(), "jjBadge is shown when JJ enabled")
end)

-- 7. UpdateUIFromValue with JJ disabled
test("1.7 UpdateUIFromValue(2.0) without JJ: hero 2.00x, badge hidden", function()
  resetLogs()
  XPRateControlDB.jjEnabled = false
  XPRate.UpdateUIFromValue(2.0, nil)

  local hero = _G["XPRateValueTextWidget"]
  assert_equal("2.00x", hero:GetText(), "hero text shows set rate 2.00x without JJ")
  assert_equal(false, XPRate.jjBadge:IsShown(), "jjBadge hidden when JJ disabled")
end)

-- 8. JJ checkbox OnClick toggles DB and hero display
test("1.8 JJ checkbox OnClick toggles jjEnabled and hero text", function()
  resetLogs()
  XPRateControlDB.jjEnabled = true
  XPRateControlDB.lastRate = 2.0
  XPRate.UpdateUIFromValue(2.0, nil)

  local hero = _G["XPRateValueTextWidget"]
  assert_equal("3.00x", hero:GetText(), "hero starts at 3.00x with JJ on")

  XPRate.jjCheckbox:SetChecked(false)
  XPRate.jjCheckbox.scripts.OnClick(XPRate.jjCheckbox)
  assert_equal(false, XPRateControlDB.jjEnabled, "unchecking JJ checkbox sets db.jjEnabled=false")
  assert_equal("2.00x", hero:GetText(), "hero drops to 2.00x after disabling JJ")

  XPRate.jjCheckbox:SetChecked(true)
  XPRate.jjCheckbox.scripts.OnClick(XPRate.jjCheckbox)
  assert_equal(true, XPRateControlDB.jjEnabled, "checking JJ checkbox sets db.jjEnabled=true")
  assert_equal("3.00x", hero:GetText(), "hero rises to 3.00x after enabling JJ")
end)

-- 9. /xp status
test("1.9 /xp status shows effective rate and JJ tag", function()
  resetLogs()
  XPRateControlDB.jjEnabled = true
  XPRate.lastAppliedRate = 2.0
  XPRate.lastAppliedMode = "Manual"

  local slashHandler = SlashCmdList["XPRATECONTROL"]
  assert_true(type(slashHandler) == "function", "slash handler exists")
  slashHandler("status")

  local joined = table.concat(printedMessages, "\n")
  assert_true(joined:find("3.00", 1, true), "status output contains effective rate 3.00")
  assert_true(joined:find("JJ x1.5", 1, true), "status output contains 'JJ x1.5'")
end)

-- 10. Automation quest switch message with effective rate
test("1.10 Automation quest switch prints effective rate and applies set rate", function()
  resetLogs()
  XPRateControlDB.autoQuest = true
  XPRateControlDB.questRate = 2.0
  XPRateControlDB.quietAuto = false
  XPRateControlDB.jjEnabled = true
  XPRate.isQuestNPCActive = true
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRate.EvaluateAutomation(false, "JJ Test")

  assert_true(hasPrintedMessageClean("Auto-Switched -> 2.00x (3.00x w/ JJ) via"), "Auto-Switched message shows effective rate (color codes stripped)")
  assert_equal(2.0, XPRate.lastAppliedRate, "XPRate.lastAppliedRate is set rate 2.0")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
