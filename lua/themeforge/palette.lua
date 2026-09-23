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
  local function relative_luminance(hex)
    local c = M.hex_to_rgb(hex)
    local function linearize(v)
      v = v / 255
      return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
    end
    return 0.2126 * linearize(c.r) + 0.7152 * linearize(c.g) + 0.0722 * linearize(c.b)
  end
  local l1 = relative_luminance(hex_a)
  local l2 = relative_luminance(hex_b)
  if l1 < l2 then l1, l2 = l2, l1 end
  return (l1 + 0.05) / (l2 + 0.05)
end

-- Apply palette mix blending to a color
-- Apply palette adjustments. `background` is used by opacity to fade a color
-- toward the theme background instead of silently doing nothing.
function M.apply_mix(hex, mix, background)
  if not hex or not M.is_valid_hex(hex) then return hex end
  mix = mix or {}
  local result = hex

  if mix.purple and mix.purple > 0 then
    result = M.shift_hue(result, (270 - 180) * mix.purple / 100)
    result = M.adjust_saturation(result, mix.purple * 0.1)
  end
  if mix.blue and mix.blue > 0 then
    result = M.shift_hue(result, (210 - 180) * mix.blue / 100)
    result = M.adjust_saturation(result, mix.blue * 0.05)
  end
  if mix.green and mix.green > 0 then
    result = M.shift_hue(result, (120 - 180) * mix.green / 100)
    result = M.adjust_saturation(result, mix.green * 0.05)
  end
  if mix.pink and mix.pink > 0 then
    result = M.shift_hue(result, (330 - 180) * mix.pink / 100)
    result = M.adjust_saturation(result, mix.pink * 0.08)
  end
  if mix.orange and mix.orange > 0 then
    result = M.shift_hue(result, (30 - 180) * mix.orange / 100)
    result = M.adjust_saturation(result, mix.orange * 0.07)
  end
  if mix.cyan and mix.cyan > 0 then
    result = M.shift_hue(result, (180 - 180) * mix.cyan / 100)
    result = M.adjust_saturation(result, mix.cyan * 0.06)
  end
  if mix.warm and mix.warm > 0 then
    result = M.shift_hue(result, (30 - 180) * mix.warm / 100)
    result = M.adjust_saturation(result, mix.warm * 0.08)
  end

  if mix.saturation and mix.saturation ~= 50 then
    local delta = (mix.saturation - 50) * 1.5
    result = M.adjust_saturation(result, delta)
  end

  if mix.brightness and mix.brightness ~= 50 then
    local delta = (mix.brightness - 50) * 1.2
    result = M.adjust_lightness(result, delta)
  end

  if background and M.is_valid_hex(background) and mix.opacity and mix.opacity < 100 then
    result = M.mix(background, result, math.max(0, math.min(100, mix.opacity)) / 100)
  end

  return result
end

return M
