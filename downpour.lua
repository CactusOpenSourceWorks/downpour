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
This module contains core definitions for Downpour.
------------------------------------------
]]--

downpour = {}

local _channels = {io.stdout}

downpour.log = {}

local _set_channels = function (...)
  if #{...} > 0 then
    _channels = {...}
  end
end

local _get_channels = function ()
  return _channels
end

local _write_single = function (channel, formatter, ...)
  if channel ~= nil then
    channel:write(string.format(formatter,  ...))
  end
end

local _write = function (formatter, ...)
  if #_channels == 1 then
    _write_single(_channels[1], formatter, ...)
  else
    for i = 1, #_channels, 1 do
      _write_single(_channels[i], formatter, ...)
    end
  end
end

downpour.log["set_channels"] = _set_channels
downpour.log["get_channels"] = _get_channels
downpour.log["write"] = _write

downpour["checks"] = function (...) end

-- | begin_code_ignore
-- If, at this point, "checks" has already been loaded (which is identified by the existence of _G.checks and _G.checkers as outlined here),
-- then just use it. Otherwise, bail out... (until we have the time to roll our own, that is. This is almost always a necessity to have).
if _G["checks"] ~= nil and type(_G["checks"]) == "function" and _G["checkers"] ~= nil and type(_G["checkers"]) == "table" then
  downpour["checks"] = _G["checks"]
else
  _write("Warning! Support for argument checking is currently disabled, as the checks module couldn't be found.\n")
end
-- | end_code_ignore

return downpour
