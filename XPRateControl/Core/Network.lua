-- Core/Network.lua — Rate formatting, rate colors, and chat server commands for XPRateControl
local addonName, XPRate = ...

local CLR           = XPRate.CLR
local RATE_MIN      = XPRate.RATE_MIN
local RATE_MAX      = XPRate.RATE_MAX
local DEFAULT_RATE  = XPRate.DEFAULT_RATE
local RATE_ZERO_SUB = XPRate.RATE_ZERO_SUB

function XPRate.FormatRate(val)
  return string.format("%.2f", val)
end

function XPRate.ClampRate(val)
  if val < RATE_MIN then return RATE_MIN end
  if val > RATE_MAX then return RATE_MAX end
  return val
end

function XPRate.IsJJEnabled()
  if type(XPRateControlDB) ~= "table" then return false end
  return XPRateControlDB.jjEnabled == true
end

function XPRate.EffectiveRate(rate)
  if rate <= 0 then return 0 end
  if XPRate.IsJJEnabled() then
    -- Server base rates are x1/x2 only (.weekendxp rate 1); with JJ active the
    -- effective rate snaps to the nearest canonical base x 1.5 (1.50x or 3.00x).
    local base = (rate >= 1.5) and 2 or 1
    return base * (XPRate.JJ_MULT or 1.5)
  end
  return rate
end

function XPRate.RateColor(val)
  if val <= 0 then return CLR.red end
  if val < 1 then return CLR.dim end
  if val == 1 then return CLR.gold end
  if val <= 1.5 then return CLR.green end
  return CLR.cyan
end

function XPRate.RateLabel(val)
  if val <= 0 then return "OFF" end
  if val == 1 then return "Blizzlike" end
  if val >= 2 then return "Maximum" end
  return ""
end

function XPRate.SendXPCommand(rate)
  local rateStr = (rate == 0) and RATE_ZERO_SUB or XPRate.FormatRate(rate)
  SendChatMessage(".w r " .. rateStr, "SAY")
end

function XPRate.SendJJCommand(enabled)
  local state = enabled and "on" or "off"
  SendChatMessage(".weekendxp j " .. state, "SAY")
end

-- Unified Apply Helper
function XPRate.ApplyRate(rate, silent)
  rate = XPRate.ClampRate(tonumber(rate) or DEFAULT_RATE)
  XPRate.SendXPCommand(rate)

  if XPRateControlDB then
    XPRateControlDB.lastRate = rate
  end
  XPRate.lastAppliedRate = rate

  if XPRate.XPRateSliderWidget then
    XPRate.XPRateSliderWidget:SetValue(rate)
  end

  if XPRateMinimapButtonBorder then
    local rc = XPRate.RateColor(XPRate.EffectiveRate(rate))
    XPRateMinimapButtonBorder:SetVertexColor(rc[1], rc[2], rc[3])
  end

  local db = XPRateControlDB
  local showToast = (not silent) and (not db or db.showToast ~= false)
  local showChat = (not silent) and (not db or db.showChat ~= false)

  if showToast then
    XPRate.ShowToast(string.format("Sent %sx [OK]", XPRate.FormatRate(rate)), false)
  end
  if showChat then
    local eff = XPRate.EffectiveRate(rate)
    if eff ~= rate then
      XPRate.PrintMessage("XP rate set to " .. XPRate.FormatRate(rate) .. "x (" .. XPRate.FormatRate(eff) .. "x with Joyous Journeys)")
    else
      XPRate.PrintMessage("XP rate set to " .. XPRate.FormatRate(rate) .. "x")
    end
  end
end
