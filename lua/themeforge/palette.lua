local M = {}

function M.hex_to_rgb(hex)
  hex = hex:gsub("^#", "")
  return {
    r = tonumber(hex:sub(1, 2), 16),
    g = tonumber(hex:sub(3, 4), 16),
    b = tonumber(hex:sub(5, 6), 16),
  }
end

function M.rgb_to_hex(r, g, b)
  r = math.max(0, math.min(255, math.floor(r + 0.5)))
  g = math.max(0, math.min(255, math.floor(g + 0.5)))
  b = math.max(0, math.min(255, math.floor(b + 0.5)))
  return string.format("#%02x%02x%02x", r, g, b)
end

function M.mix(hex_a, hex_b, ratio)
  ratio = math.max(0, math.min(1, ratio))
  local a = M.hex_to_rgb(hex_a)
  local b = M.hex_to_rgb(hex_b)
  return M.rgb_to_hex(
    a.r + (b.r - a.r) * ratio,
    a.g + (b.g - a.g) * ratio,
    a.b + (b.b - a.b) * ratio
  )
end

-- Convert RGB to HSL
local function rgb_to_hsl(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s, l = 0, 0, (max + min) / 2
  if max ~= min then
    local d = max - min
    s = l > 0.5 and d / (2 - max - min) or d / (max + min)
    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    else
      h = (r - g) / d + 4
    end
    h = h / 6
  end
  return h * 360, s * 100, l * 100
end

local function hue_to_rgb(p, q, t)
  if t < 0 then t = t + 1 end
  if t > 1 then t = t - 1 end
  if t < 1/6 then return p + (q - p) * 6 * t end
  if t < 1/2 then return q end
  if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
  return p
end

-- Convert HSL to RGB
local function hsl_to_rgb(h, s, l)
  h, s, l = h / 360, s / 100, l / 100
  if s == 0 then
    local v = l * 255
    return v, v, v
  end
  local q = l < 0.5 and l * (1 + s) or l + s - l * s
  local p = 2 * l - q
  return
    hue_to_rgb(p, q, h + 1/3) * 255,
    hue_to_rgb(p, q, h) * 255,
    hue_to_rgb(p, q, h - 1/3) * 255
end

function M.shift_hue(hex, degrees)
  local c = M.hex_to_rgb(hex)
  local h, s, l = rgb_to_hsl(c.r, c.g, c.b)
  h = (h + degrees) % 360
  local r, g, b = hsl_to_rgb(h, s, l)
  return M.rgb_to_hex(r, g, b)
end

function M.adjust_saturation(hex, delta)
  local c = M.hex_to_rgb(hex)
  local h, s, l = rgb_to_hsl(c.r, c.g, c.b)
  s = math.max(0, math.min(100, s + delta))
  local r, g, b = hsl_to_rgb(h, s, l)
  return M.rgb_to_hex(r, g, b)
end

function M.adjust_lightness(hex, delta)
  local c = M.hex_to_rgb(hex)
  local h, s, l = rgb_to_hsl(c.r, c.g, c.b)
  l = math.max(0, math.min(100, l + delta))
  local r, g, b = hsl_to_rgb(h, s, l)
  return M.rgb_to_hex(r, g, b)
end

function M.is_valid_hex(str)
  if type(str) ~= "string" then return false end
  return str:match("^#%x%x%x%x%x%x$") ~= nil
end

function M.contrast_ratio(hex_a, hex_b)
  return require("themeforge.color").wcag_ratio(hex_a, hex_b)
end

-- Palette keys that act as surfaces (backgrounds) or neutral text. Everything
-- else is treated as an accent.
M.SURFACE_KEYS = { bg = true, bg2 = true, bg3 = true, selection = true }
M.NEUTRAL_KEYS = { fg = true, fg2 = true, comment = true }

function M.role_of(key)
  if M.SURFACE_KEYS[key] then return "surface" end
  if M.NEUTRAL_KEYS[key] then return "neutral" end
  return "accent"
end

-- OKLCH hue each tint slider pulls toward.
local TINT_HUES = {
  purple = 305, blue = 258, green = 145, cyan = 205, pink = 350, orange = 50, warm = 70,
}
local TINT_ORDER = { "purple", "blue", "green", "cyan", "pink", "orange", "warm" }

-- How strongly each role reacts to the sliders. Surfaces are deliberately
-- protected: brightness barely moves them, so +brightness lifts text instead
-- of washing out the background (the old HSL implementation lifted both).
local ROLE_GAIN = {
  accent  = { hue = 0.55, chroma = 0.030, sat = 1.0, light = 0.14 },
  neutral = { hue = 0.70, chroma = 0.012, sat = 0.5, light = 0.12 },
  surface = { hue = 0.90, chroma = 0.022, sat = 0.5, light = 0.025 },
}

--- Apply blend sliders to a colour in OKLCH.
--- @param hex string
--- @param mix table palette_mix (tints 0..100, saturation/brightness 0..100 centred on 50, opacity 0..100)
--- @param background string|nil theme background, used by opacity
--- @param role "accent"|"neutral"|"surface"|nil
function M.apply_mix(hex, mix, background, role)
  if not hex or not M.is_valid_hex(hex) then return hex end
  mix = mix or {}
  local color = require("themeforge.color")
  local gain = ROLE_GAIN[role or "accent"] or ROLE_GAIN.accent
  local L, C, h = color.hex_to_oklch(hex)
  local changed = false

  for _, key in ipairs(TINT_ORDER) do
    local t = (mix[key] or 0) / 100
    if t > 0 then
      -- Near-grey colours have no meaningful hue: adopt the target hue.
      h = C < 0.01 and TINT_HUES[key] or color.hue_toward(h, TINT_HUES[key], t * gain.hue)
      C = C + gain.chroma * t
      changed = true
    end
  end

  local sat = mix.saturation or 50
  if sat ~= 50 then
    C = C * (2 ^ ((sat - 50) / 25)) ^ gain.sat
    changed = true
  end

  local bright = mix.brightness or 50
  if bright ~= 50 then
    L = math.max(0, math.min(1, L + (bright - 50) / 50 * gain.light))
    changed = true
  end

  local result = changed and color.oklch_to_hex(L, math.max(0, C), h) or hex

  local opacity = mix.opacity or 100
  if role ~= "surface" and background and M.is_valid_hex(background) and opacity < 100 then
    result = color.mix(background, result, math.max(0, math.min(100, opacity)) / 100)
  end

  return result
end

--- True when a palette_mix differs from the neutral defaults.
function M.mix_is_active(mix)
  if not mix then return false end
  for _, key in ipairs(TINT_ORDER) do
    if (mix[key] or 0) > 0 then return true end
  end
  return (mix.saturation or 50) ~= 50 or (mix.brightness or 50) ~= 50 or (mix.opacity or 100) < 100
end

return M
