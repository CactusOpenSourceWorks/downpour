--[[
Copyright (c) 2017 - 2022 Stardust

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

------------------------------------------
This is a collection of day-to-day math functions, which includes a collection of
pseudo random number generators (PRNGs), which includes:
* LCG (Linear Congruential Generator), fast and works.
* Multiply-with-carry, not so fast but works great.
* Mersenne Twister: slowest, but generates high quality unique numbers.

[Note] -
The original implementation of PRNGs (in pure Lua) was written by linux-man and posted here:
https://love2d.org/forums/viewtopic.php?t=3424, released under the MIT license, which
I took and made minor modifications to it.
------------------------------------------
+ lcg(seed, param) / linear_congruential_generator(seed, param)
++ Creates a new LCG generator. Pass 0 to seed to use the random one (defined in the local function seed()). Additionally, pass
++ either: "ansi_c", "tp", "mvc"/"mvcpp" or "nr" to specify the generator's parameter.
++ After creating the generator with lcg(), use generator:random(a, b) to generate a new
++ random number.
------------------------------------------
+ mwc(seed, param) / multiply_with_carry(seed, param)
++ Creates a new multiply-with-carry generator. The rest is the same with the LCG generator.
++ After creating the generator with mwc(), use generator:random(a, b) to generate a new
++ random number.
------------------------------------------
++ mt(seed) / mersenne_twister(seed)
++ Creates a new Mersenne Twister generator. After creating the generator with mt(), use generator:random(a, b)
++ to generate a new random number.
------------------------------------------
++ lerp(a, b, t, method)
++ Interpolates between a and b according to the factor f (f is in the range [0; 1].
++ Additionally, you can pass what interpolating method you want to use. Available methods:
++ "linear" -> lerp(a, b, t, "linear"): Linear interpolation.
++ "cosine" -> lerp(a, b, t, "cosine"): Cosine interpolation, which is a bit more computational complex than the linear method.
------------------------------------------
++ integrate(f, a, b, method)
++ Performs numerical integration using using the f(x) function which takes one argument x over the range [a;b].
++ Several techniques are available for computing the integral, which can be specified through the fourth parameter:
++ "rectangle": Rectangle method. Usually is a sum of N (fixed) rectangles made up to cover the integral. Fast and has
++ an option to adjust the number of rectangles, which is N, for better accuracy. (N is an integral constant and lies in
++ downpour.math.integrate_N)
++ "trapezoid": Trapezoidal method, which is basically the same as the rectangle method but uses trapezoids. It uses
++ non-uniform formula to calculate the given integral, and also uses integrate_N for the number of trapezoids.
++ "simpson": Simpson's method, which consists of a single calculation. An extension, which is "simpson3_8", which uses
++ Simpson's 3/8 rule. (https://en.wikipedia.org/wiki/Simpson%27s_rule#Simpson.27s_3.2F8_rule)
++ "gaussian": The most accurate method available, which is Gauss-Legendre numerical integration method. I personally use
++ a fixed constant table which contains pre-computed values instead of rolling my own implementation of one of the
++ weighted functions. n = 10.
------------------------------------------
++ e(n)
++ Calculates and returns the value of the e constant with the specified depth of n. The higher n is, the more accurate e will
++ be, but more calculations will be involved to achieve the final result.
------------------------------------------
++ round(n, d)
++ Performs rounding on n to the maximum of d digits behind the decimal point. For example, round(3.14159, 1) would yield 3.1.
]]--

local downpour = require("downpour")

require("downpour-io")

downpour.math = {}

downpour.math["integrate_N"] = 64

local normalize = downpour.numeric.normalize
local bit_and   = downpour.numeric.bit_and
local bit_or    = downpour.numeric.bit_or
local bit_xor   = downpour.numeric.bit_xor

local seed = function ()
  return normalize(os.time())
end

downpour.math.__mersenne_twister__ = {}
downpour.math.__mersenne_twister__.__index = downpour.math.__mersenne_twister__

function downpour.math.__mersenne_twister__:random_seed (s)
  if not s then s = seed() end
  self.mt[0] = normalize(s)

  for i = 1, 623 do
    self.mt[i] = normalize(0x6c078965 * bit_xor(self.mt[i - 1], math.floor(self.mt[i - 1] / 0x40000000)) + i)
  end
end

function downpour.math.__mersenne_twister__:random (a, b)
  local y
  if self.index == 0 then
    for i = 0, 623 do
      y = self.mt[(i + 1) % 624] % 0x80000000
      self.mt[i] = bit_xor(self.mt[(i + 397) % 624], math.floor(y / 2))
      if y % 2 ~= 0 then self.mt[i] = bit_xor(self.mt[i], 0x9908b0df) end
    end
  end

  y = self.mt[self.index]
  y = bit_xor(y, math.floor(y / 0x800))
  y = bit_xor(y, bit_and(normalize(y * 0x80), 0x9d2c5680))
  y = bit_xor(y, bit_and(normalize(y * 0x8000), 0xefc60000))
  y = bit_xor(y, math.floor(y / 0x40000))
  self.index = (self.index + 1) % 624

  if not a then return y / 0x80000000
  elseif not b then
    if a == 0 then return y
    else return 1 + (y % a)
    end
  else
    return a + (y % (b - a + 1))
  end
end

function downpour.math.mersenne_twister (s)
  local t = {}
  setmetatable(t, downpour.math.__mersenne_twister__)
  t.mt = {}
  t.index = 0
  t:random_seed(s)

  return t
end

function downpour.math.mt (s)
  return downpour.math.mersenne_twister(s)
end

downpour.math.__lcg__ = {}
downpour.math.__lcg__.__index = downpour.math.__lcg__

function downpour.math.__lcg__:random_seed (s)
  if not s then s = seed() end
  self.x = normalize(s)
end

function downpour.math.__lcg__:random (a, b)
  local y = (self.a * self.x + self.c) % self.m
  self.x = y
  if not a then return y / 0x10000
  elseif not b then
    if a == 0 then return y
    else return 1 + (y % a) end
  else
    return a + (y % (b - a + 1))
  end
end

function downpour.math.linear_congruential_generator (s, r)
  local t = {}
  setmetatable(t, downpour.math.__lcg__)

  if not r then
    r = "ansi_c"
  end

  if r == "ansi_c" then
    t.a, t.c, t.m = 1103515245, 12345, 0x10000
  elseif r == "nr" then -- https://en.wikipedia.org/wiki/Numerical_Recipes
    t.a, t.c, t.m = 1664525, 1013904223, 0x10000
  elseif (r == "mvc") or (r == "mvcpp") then
    t.a, t.c, t.m = 214013, 2531011, 0x10000
  elseif r == "tp" then
    t.a, t.c, t.m = 33797, 1, 0x10000
  else
  end

  t:random_seed(s)
  return t
end

function downpour.math.lcg (s, r)
  return downpour.math.linear_congruential_generator(s, r)
end

downpour.math.__multiply_with_carry__ = {}
downpour.math.__multiply_with_carry__.__index = downpour.math.__multiply_with_carry__

function downpour.math.__multiply_with_carry__:random (a, b)
  local m = self.m
  local t = self.a * self.x + self.c
  local y = t % m
  self.x = y
  self.c = math.floor(t / m)
  if not a then return y / 0x10000
  elseif not b then
    if a == 0 then return y
    else return 1 + (y % a) end
  else
    return a + (y % (b - a + 1))
  end
end

function downpour.math.__multiply_with_carry__:random_seed (s)
  if not s then s = seed() end
  self.c = self.ic
  self.x = normalize(s)
end

function downpour.math.multiply_with_carry (s, r)
  local t = {}
  setmetatable(t, downpour.math.__multiply_with_carry__)

  if not r then
    r = "ansi_c"
  end

  if r == "ansi_c" then
    t.a, t.c, t.m = 1103515245, 12345, 0x10000
  elseif r == "nr" then -- https://en.wikipedia.org/wiki/Numerical_Recipes
    t.a, t.c, t.m = 1664525, 1013904223, 0x10000
  elseif (r == "mvc") or (r == "mvcpp") then
    t.a, t.c, t.m = 214013, 2531011, 0x10000
  elseif r == "tp" then
    t.a, t.c, t.m = 33797, 1, 0x10000
  else
  end

  t.ic = t.c
  t:random_seed(s)

  return t
end

function downpour.math.mwc (s, r)
  return downpour.math.multiply_with_carry(s, r)
end

downpour.math["factorial"] = function (n)
  if n <= 1 then return n else return n * downpour.math.factorial(n - 1) end
end

downpour.math["e"] = function (n)
  n = n or 16
  local e = 0.0

  for i = 1, n do e = e + (1 / downpour.math.factorial(i)) end
  return (e + 1)
end

local __gauss_wtable__ = {
  { w = 0.2955242247147529, x = -0.1488743389816312 },
  { w = 0.2955242247147529, x =  0.1488743389816312 },
  { w = 0.2692667193099963, x = -0.4333953941292472 },
  { w = 0.2692667193099963, x =  0.4333953941292472 },
  { w = 0.2190863625159820, x = -0.6794095682990244 },
  { w = 0.2190863625159820, x =  0.6794095682990244 },
  { w = 0.1494513491505806, x = -0.8650633666889845 },
  { w = 0.1494513491505806, x =  0.8650633666889845 },
  { w = 0.0666713443086881, x = -0.9739065285171717 },
  { w = 0.0666713443086881, x =  0.9739065285171717 }
}

downpour.math["integrate"] = function (f, a, b, method)
  if not method then method = tostring("rectangle") end
  if downpour.math.integrate_N <= 0 then downpour.math.integrate_N = 64 end
  local r = 0.0

  if f ~= nil then
    if method == "rectangle" then -- https://en.wikipedia.org/wiki/Rectangle_method
      local h, sum = (b - a) / downpour.math.integrate_N, 0.0

      for n = 0, downpour.math.integrate_N - 1 do
        sum = sum + f(a + n * h)
      end

      r = h * sum
    elseif method == "trapezoid" then -- https://en.wikipedia.org/wiki/Trapezoidal_rule
      local h, sum = (b - a) / downpour.math.integrate_N, 0.0

      for n = 1, downpour.math.integrate_N do
        sum = sum + (f(a + (n - 1) * h) + f(a + n * h))
      end

      r = (h / 2.0) * sum
    elseif method == "simpson" then -- https://en.wikipedia.org/wiki/Simpson%27s_rule
      r = ((b - a) / 6.0) * (f(a) + 4 * f((a + b) / 2) + f(b))
    elseif method == "simpson3_8" then
      r = ((b - a) / 8.0) * (f(a) + 3 * f((2 * a + b) / 3.0) + 3 * f((a + 2 * b) / 3.0) + f(b))
    elseif method == "gaussian" then
      local m, p1, p2, sum = (b - a) / 2.0, (b - a) / 2.0, (a + b) / 2.0, 0.0

      for n = 1, #__gauss_wtable__ do
        sum = sum + (__gauss_wtable__[n].w * f(p1 * __gauss_wtable__[n].x + p2))
      end

      r = m * sum
    end
  end

  return r
end

downpour.math["lerp"] = function (a, b, t, method)
  if not method then method = tostring("linear") end
  local r = 0.0

  if method == "linear" then
    r = a + (b - a) * t
  elseif method == "cosine" then
    local v = (1 - math.cos(t * math.pi)) / 2.0
    r = a * (1 - v) + b * v
  end

  return r
end

downpour.math["round"] = function (n, d)
  if (d ~= nil) and (d > 0) then
    local m = 10 ^ d
    return math.floor(n * m + 0.5) / m
  end

  return math.floor(n + 0.5)
end

downpour.math["sgn"] = function (x)
  if x > 0.0 then
    return 1.0
  elseif x < 0.0 then
    return -1.0
  end

  return 0.0
end

return downpour.math
