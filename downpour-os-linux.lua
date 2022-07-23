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
This module contains core definitions for the Downpour OS API for Linux.
You should not use this interface when making OS calls. Instead, it's generally recommended that you use
the higher, OS-independent interface provided in downpour-os.
------------------------------------------
Dependencies:
[X] downpour
[X] downpour-os
[X] downpour-io (If the safe switch is enabled in <downpour-os> through safe().)
------------------------------------------
]]--

local downpour = require("downpour")

require("downpour-os")

local osutils = downpour.osutils
local log = downpour.log

osutils.linux = {}

osutils.linux = {
  ["__init__"] = false
}

local __os_table__ = {
  ["xmessage"] = "/usr/bin/xmessage"
}

osutils.linux["init"] = function ()
  log.write("%s", "[!] - downpour.osutils.linux.init(): Initializing the Linux subsystem...")

  if osutils.linux["__init__"] == false then
    log.write("%s", "[!] - downpour.osutils.linux.init(): Linux subsystem successfully initialized.")
    osutils.linux["__init__"] = true
    return true
  end
end

osutils.linux["is_init"] = function ()
  return osutils.linux["__init__"]
end

osutils.linux["alert"] = function (title, message)
  local args = __os_table__["xmessage"] .. " " .. title .. " " .. message

  os.execute(args)
end -- // osutils.linux = {}
