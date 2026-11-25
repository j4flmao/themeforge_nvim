-- ThemeForge color science helpers (pure Lua, no dependencies).
--
-- * OKLab / OKLCH conversion (Björn Ottosson, 2020/2021 matrices)
-- * CSS Color 4 gamut mapping (binary search on chroma, JND 0.02)
-- * WCAG 2.x contrast ratio and role-based grading
-- * APCA Lc (0.0.98G constants) as an advisory perceptual contrast number
-- * Colour-vision-deficiency simulation (Viénot 1999 for protan/deutan,
--   Brettel 1997 for tritan, both in linear RGB) and deltaE in OKLab
local M = {}

local cbrt = function(x) return x < 0 and -((-x) ^ (1 / 3)) or x ^ (1 / 3) end
local clamp = function(x, lo, hi) return math.max(lo, math.min(hi, x)) end

-- ── sRGB ───────────────────────────────────────────────────────────────────

function M.is_hex(s)
  return type(s) == "string" and s:match("^#%x%x%x%x%x%x$") ~= nil
end

function M.hex_to_rgb(hex)
  hex = hex:gsub("^#", "")
  return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

function M.rgb_to_hex(r, g, b)
  local function byte(v) return clamp(math.floor(v * 255 + 0.5), 0, 255) end
  return string.format("#%02x%02x%02x", byte(r), byte(g), byte(b))
end

local function to_linear(c)
  return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function from_linear(c)
  return c <= 0.0031308 and c * 12.92 or 1.055 * (c ^ (1 / 2.4)) - 0.055
end

-- ── OKLab / OKLCH ──────────────────────────────────────────────────────────

local function linear_to_oklab(r, g, b)
  local l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
  local m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
  local s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
  return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
end

local function oklab_to_linear(L, a, b)
  local l = (L + 0.3963377774 * a + 0.2158037573 * b) ^ 3
  local m = (L - 0.1055613458 * a - 0.0638541728 * b) ^ 3
  local s = (L - 0.0894841775 * a - 1.2914855480 * b) ^ 3
  return 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
end

function M.hex_to_oklab(hex)
  local r, g, b = M.hex_to_rgb(hex)
  return linear_to_oklab(to_linear(r), to_linear(g), to_linear(b))
end

function M.hex_to_oklch(hex)
  local L, a, b = M.hex_to_oklab(hex)
  local C = math.sqrt(a * a + b * b)
  local h = C < 4e-6 and 0 or (math.deg(math.atan2 and math.atan2(b, a) or math.atan(b, a)) % 360)
  return L, C, h
end

local function oklch_to_linear(L, C, h)
  local rad = math.rad(h)
  return oklab_to_linear(L, C * math.cos(rad), C * math.sin(rad))
end

local function in_gamut(r, g, b)
  local e = 1e-6
  return r >= -e and r <= 1 + e and g >= -e and g <= 1 + e and b >= -e and b <= 1 + e
end

local function delta_eok_lab(L1, a1, b1, L2, a2, b2)
  return math.sqrt((L1 - L2) ^ 2 + (a1 - a2) ^ 2 + (b1 - b2) ^ 2)
end

--- OKLCH -> hex using the CSS Color 4 gamut-mapping algorithm.
function M.oklch_to_hex(L, C, h)
  if L >= 1 then return "#ffffff" end
  if L <= 0 then return "#000000" end
  local r, g, b = oklch_to_linear(L, C, h)
  if in_gamut(r, g, b) then
    return M.rgb_to_hex(from_linear(clamp(r, 0, 1)), from_linear(clamp(g, 0, 1)), from_linear(clamp(b, 0, 1)))
  end
  local JND, EPS = 0.02, 0.0001
  local lo, hi = 0, C
  local function clipped(c)
    local cr, cg, cb = oklch_to_linear(L, c, h)
    return clamp(cr, 0, 1), clamp(cg, 0, 1), clamp(cb, 0, 1), cr, cg, cb
  end
  local best_r, best_g, best_b = clipped(C)
  while hi - lo > EPS do
    local mid = (lo + hi) / 2
    local cr, cg, cb, ur, ug, ub = clipped(mid)
    if in_gamut(ur, ug, ub) then
      lo = mid
      best_r, best_g, best_b = cr, cg, cb
    else
      local L1, a1, b1 = linear_to_oklab(cr, cg, cb)
      local rad = math.rad(h)
      local E = delta_eok_lab(L1, a1, b1, L, mid * math.cos(rad), mid * math.sin(rad))
      if E < JND then
        best_r, best_g, best_b = cr, cg, cb
        if JND - E < EPS then break end
        lo = mid
      else
        hi = mid
      end
    end
  end
  return M.rgb_to_hex(from_linear(best_r), from_linear(best_g), from_linear(best_b))
end

--- Distance between two colours in OKLab (deltaEOK).
function M.delta_eok(hex_a, hex_b)
  local L1, a1, b1 = M.hex_to_oklab(hex_a)
  local L2, a2, b2 = M.hex_to_oklab(hex_b)
  return delta_eok_lab(L1, a1, b1, L2, a2, b2)
end

--- Perceptual mix of two colours in OKLab (t = 0 -> a, t = 1 -> b).
function M.mix(hex_a, hex_b, t)
  t = clamp(t, 0, 1)
  local L1, a1, b1 = M.hex_to_oklab(hex_a)
  local L2, a2, b2 = M.hex_to_oklab(hex_b)
  local r, g, b = oklab_to_linear(L1 + (L2 - L1) * t, a1 + (a2 - a1) * t, b1 + (b2 - b1) * t)
  return M.rgb_to_hex(from_linear(clamp(r, 0, 1)), from_linear(clamp(g, 0, 1)), from_linear(clamp(b, 0, 1)))
end

--- Rotate hue `h` toward `target` along the shortest arc by fraction `t`.
function M.hue_toward(h, target, t)
  local d = ((target - h + 540) % 360) - 180
  return (h + d * t) % 360
end

-- ── Contrast ───────────────────────────────────────────────────────────────

function M.luminance(hex)
  local r, g, b = M.hex_to_rgb(hex)
  return 0.2126 * to_linear(r) + 0.7152 * to_linear(g) + 0.0722 * to_linear(b)
end

--- WCAG 2.x contrast ratio (1..21).
function M.wcag_ratio(a, b)
  local l1, l2 = M.luminance(a), M.luminance(b)
  if l1 < l2 then l1, l2 = l2, l1 end
  return (l1 + 0.05) / (l2 + 0.05)
end

--- APCA Lc (0.0.98G). Signed: negative means light text on a dark background.
--- Advisory only: WCAG 2 stays the pass/fail number.
function M.apca_lc(text, bg)
  local function y(hex)
    local r, g, b = M.hex_to_rgb(hex)
    local v = 0.2126729 * r ^ 2.4 + 0.7151522 * g ^ 2.4 + 0.0721750 * b ^ 2.4
    if v <= 0.022 then v = v + (0.022 - v) ^ 1.414 end
    return v
  end
  local ty, by = y(text), y(bg)
  if math.abs(by - ty) < 0.0005 then return 0 end
  local lc
  if by > ty then
    local s = (by ^ 0.56 - ty ^ 0.57) * 1.14
    lc = s < 0.1 and 0 or s - 0.027
  else
    local s = (by ^ 0.65 - ty ^ 0.62) * 1.14
    lc = s > -0.1 and 0 or s + 0.027
  end
  return lc * 100
end

--- Minimum WCAG ratio per editor role. One table shared by the panel and the
--- doctor so both always agree.
M.ROLE_MIN = {
  text = 4.5,      -- Normal, identifiers, keywords, diagnostics virtual text
  comment = 3.0,   -- comments: readable but intentionally subdued
  subtle = 2.0,    -- line numbers, NonText, inlay hints
  border = 1.4,    -- separators and borders against the background
}

--- Grade a ratio for a role: returns label, ok.
function M.grade(ratio, role)
  local min = M.ROLE_MIN[role or "text"] or 4.5
  if ratio >= 7 and (role == nil or role == "text") then return "AAA", true end
  if ratio >= min then return (role == nil or role == "text") and "AA" or "OK", true end
  return "LOW", false
end

--- Nudge `fg` lightness away from `bg` until it reaches `min_ratio`.
function M.ensure_contrast(fg, bg, min_ratio)
  if not (M.is_hex(fg) and M.is_hex(bg)) then return fg end
  if M.wcag_ratio(fg, bg) >= min_ratio then return fg end
  local L, C, h = M.hex_to_oklch(fg)
  local bgL = M.hex_to_oklch(bg)
  local dir = L >= bgL and 1 or -1
  if (dir > 0 and L >= 0.99) or (dir < 0 and L <= 0.01) then dir = -dir end
  local out = fg
  for _ = 1, 60 do
    L = clamp(L + dir * 0.01, 0, 1)
    out = M.oklch_to_hex(L, C, h)
    if M.wcag_ratio(out, bg) >= min_ratio or L <= 0 or L >= 1 then break end
  end
  return out
end

-- ── Colour vision deficiency ───────────────────────────────────────────────

local VIENOT = {
  protan = { { 0.11238, 0.88762, 0 }, { 0.11238, 0.88762, 0 }, { 0.00401, -0.00401, 1 } },
  deutan = { { 0.29275, 0.70725, 0 }, { 0.29275, 0.70725, 0 }, { -0.02234, 0.02234, 1 } },
}
local BRETTEL_N = { 0.03901, -0.02788, -0.01113 }
local BRETTEL_1 = { { 1.01277, 0.13548, -0.14826 }, { -0.01243, 0.86812, 0.14431 }, { 0.07589, 0.80500, 0.11911 } }
local BRETTEL_2 = { { 0.93678, 0.18979, -0.12657 }, { 0.06154, 0.81526, 0.12320 }, { -0.37562, 1.12767, 0.24796 } }

local function mul(m, r, g, b)
  return m[1][1] * r + m[1][2] * g + m[1][3] * b,
    m[2][1] * r + m[2][2] * g + m[2][3] * b,
    m[3][1] * r + m[3][2] * g + m[3][3] * b
end

--- Simulate how `hex` looks with a deficiency ("protan", "deutan", "tritan").
function M.simulate_cvd(hex, kind, severity)
  severity = severity or 1
  local r, g, b = M.hex_to_rgb(hex)
  r, g, b = to_linear(r), to_linear(g), to_linear(b)
  local sr, sg, sb
  if kind == "tritan" then
    local dot = r * BRETTEL_N[1] + g * BRETTEL_N[2] + b * BRETTEL_N[3]
    sr, sg, sb = mul(dot >= 0 and BRETTEL_1 or BRETTEL_2, r, g, b)
  else
    sr, sg, sb = mul(VIENOT[kind] or VIENOT.deutan, r, g, b)
  end
  sr = severity * sr + (1 - severity) * r
  sg = severity * sg + (1 - severity) * g
  sb = severity * sb + (1 - severity) * b
  return M.rgb_to_hex(from_linear(clamp(sr, 0, 1)), from_linear(clamp(sg, 0, 1)), from_linear(clamp(sb, 0, 1)))
end

M.CVD_KINDS = { "protan", "deutan", "tritan" }

--- Smallest deltaEOK between two colours across normal vision and the three
--- dichromacies. Below ~0.08 the pair is hard to tell apart (heuristic).
function M.min_cvd_distance(a, b)
  local worst, worst_kind = M.delta_eok(a, b), "normal"
  for _, kind in ipairs(M.CVD_KINDS) do
    local d = M.delta_eok(M.simulate_cvd(a, kind), M.simulate_cvd(b, kind))
    if d < worst then worst, worst_kind = d, kind end
  end
  return worst, worst_kind
end

return M
