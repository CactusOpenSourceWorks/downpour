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
]]--

local downpour = require("downpour")
require("downpour-os")

local _checks = downpour.checks

local lfs = require("lfs")

local log       = downpour.log
local sbyte     = string.byte
local schar     = string.char
local sgmatch   = string.gmatch
local tconcat   = table.concat
local stdrandom = math.random

downpour.ioutils = {}

-- Mimics the ternary operator just as in C-like languages, which Lua currently lacks.
-- Returns f if c evaluates to either false or nil, t otherwise.
local _ternary = function (c, t, f)
  _checks("boolean", "?", "?")

  if (c == nil) or (c == false) then return f end
  return t
end

downpour.ioutils["ternary"] = _ternary

downpour.ioutils.numericutils = {}

local normalize = function (n)
  return (n % 0x80000000)
end

downpour.ioutils.numericutils["normalize"] = normalize

downpour.ioutils.numericutils["bit_and"] = function (a, b)
  local r, m = 0, 0
  for m = 0, 31 do
  if (a % 2 == 1) and (b % 2 == 1) then
    r = r + 2 ^ m
  end
  if a % 2 ~= 0 then a = a - 1 end
  if b % 2 ~= 0 then b = b - 1 end
  end

  return normalize(r)
end

downpour.ioutils.numericutils["bit_or"] = function (a, b)
  local r, m = 0, 0
  for m = 0, 31 do
  if (a % 2 == 1) and (b % 2 == 1) then
    r = r + 2 ^ m
  end
  if a % 2 ~= 0 then a = a - 1 end
  if b % 2 ~= 0 then b = b - 1 end
  a = a / 2
  b = b / 2
  end

  return normalize(r)
end

downpour.ioutils.numericutils["bit_xor"] = function (a, b)
  local r, m = 0, 0
  for m = 0, 31 do
  if a % 2 ~= b % 2 then r = r + 2 ^ m end
  if a % 2 ~= 0 then a = a - 1 end
  if b % 2 ~= 0 then b = b - 1 end
  a = a / 2
  b = b / 2
  end

  return normalize(r)
end

-- Returns percentage of n between interval [a; b]
downpour.ioutils.numericutils["get_percent_between"] = function (a, b, n)
  return (n - a) * (100 / (b - a))
end

downpour.ioutils.numericutils["wrap"] = function (x, a, b)
  if x > b then
    return a
  elseif x < a then
    return b
  end

  return x
end

-- Returns true if the specified string is a valid digit [0-9]. If the string contains more one character,
-- the function will only take out the very first character of the string sequence, and everything else will be ignored.
downpour.ioutils.numericutils["is_digit"] = function (char)
  if (not char) or (type(char) ~= "string") then
    log.write("%s", "[!] - downpour.ioutils.numericutils.is_digit(): Bad argument passed.")
  end
  
  local range = sbyte(char, 1)
  return range >= 48 and range <= 57
end

downpour.ioutils.numericutils["map_to_range"] = function (f, a, b, x, y)
  return (f - a) / (b - a) * (y - x) + x
end

downpour.ioutils.numericutils["map_to_01"] = function (f, a, b)
  return (f - a) / (b - a)
end

downpour.ioutils.numericutils["map_from_01"] = function (f, x, y)
  return f / 1.0 * (y - x) + x
end -- // downpour.ioutils.numericutils = {}

downpour.ioutils.stringutils = {}

local _get_random_character = function ()
  return schar(_ternary(stdrandom(0, 1) == 0, 65 + stdrandom(0, 90 - 65), 97 + stdrandom(0, 122 - 97)))
end

-- Returns a single random ASCII character.
downpour.ioutils.stringutils["get_random_character"] = _get_random_character

-- Returns a random ASCII string of length n.
downpour.ioutils.stringutils["get_random_string"] = function (n)
  n = n or 16
  
  -- TODO: Leverage string buffers?
  local t = {}
  for i = 1, n do
    t[i] = _get_random_character()
  end

  return tconcat(t)
end

-- Splits a string into smaller substrings, separated by token, and return a table containing the splitted strings.
-- This function behaves similarly to C's strtok(), except it does everything in one call.
-- parse() is an alias for split() (which does exactly the same thing).
downpour.ioutils.stringutils["split"] = function (input, delimiter, transform)
  _checks("string", "string", "function|nil")
  
  if input == "" then
    return {}
  end
  
  local pattern = "([^" .. delimiter .. "]+)"
  local buffer, count = {}, 1
  transform = transform or function (s) return s end
  
  for s in sgmatch(input, pattern) do
    buffer[count] = transform(s)
    count = count + 1
  end

  return buffer
end

-- Returns true (and the position of the item in t) if s matches one of the items in table t, false otherwise.
-- length specifies the maximum number of items to be searched for in t, which can be suppressed (match_table() will then
-- use the length of the table instead.)
downpour.ioutils.stringutils["match_table"] = function (s, t, length)
  _checks("string", "table", "uint64|nil")

  length = length or #t

  for k, v in ipairs(t) do
    if k <= length then
      if s == v then
        return true, k
      end
    end
  end

  return false, -1
end

downpour.ioutils.stringutils["strip"] = function (buffer, characters)
  _checks("string", "string")
  return buffer:gsub("[".. characters:gsub("%W","%%%1") .."]", '')
end -- // downpour.ioutils.stringutils = {}

downpour.ioutils.tableutils = {}

_local_traverse = function (t, functor)
  if type(t) == "table" then
    for k, v in pairs(t) do
      functor(k)
      _local_traverse(v, functor)
    end
  else functor(t) end
end

-- Recursively traverses table t while applying a user-provided functor "functor(v)" at each
-- of the found elements. If the functor cannot be found, an empty one is supplied.
downpour.ioutils.tableutils["traverse"] = function (t, transform)
  _checks("table", "function|nil")
  _local_traverse(t, transform or function (v) end)
end

-- Tests if the specified key is in the table t without creating one.
downpour.ioutils.tableutils["is_key_valid"] = function (t, k)
  _checks("table", "string")

  for _, k1 in pairs(t) do
    if k == k1 then return true end
  end

  return false
end

_local_join = function (t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(t1[k] or false) == "table" then
      _local_join(t1[k], v)
    else
      t1[k] = v
    end
  end

  return t1
end

downpour.ioutils.tableutils["join"] = _local_join

downpour.ioutils.tableutils["sprintf"] = function (template, ...)
  local out, args = {}, {...}

  if #args > 0 then
    local c = 1
    for _, v in ipairs(template) do
      out[v] = args[c]
      c = c + 1
    end
  end

  return out
end -- // downpour.ioutils.tableutils = {}

downpour.ioutils.file = {}

local _open = function (file, mode, functor)
  local f = io.open(file, mode)
  if f then
    local r = functor(f)
    f:close()
    return r
  end

  return nil
end

downpour.ioutils.file["touch"] = function (file, data, mode)
  mode = mode or 'w'
  return _open(file, mode, function (f)
    f:write(data)
    return true
  end)
end

downpour.ioutils.file["peek"] = function (file, n, mode, functor)
  mode = mode or 'r'
  return _open(file, mode, function (f)
    local buffer = f:read(n)

    if functor ~= nil then
      local t = {}
      for i = 1, buffer:len() do
        t[i] = functor(buffer:sub(i, i))
      end

      return table.concat(t)
    end

    return buffer
  end)
end

downpour.ioutils.file["dump"] = function (file, mode)
  mode = mode or 'r'
  return _open(file, mode, function (f)
    local buffer = f:read("*a")
    return buffer
  end)
end

-- Retrieves a given file name's extension. Note that this function may not work well under Linux, as hidden files/folders
-- have in additional a leading dot character (.) at the beginning of file names, thus using get_ext() on those items does not
-- return nil, but their full names instead. (TODO: fix it)
downpour.ioutils.file["get_ext"] = function (file_name)
  _checks("string")

  if file_name == "" then
    return ""
  end

  local extension = ""

  if file_name ~= "" then
    local i, len = -1, -(#file_name) -- Invert the string length because we are going to search backwards.

    for i = -1, len, -1 do
      if file_name:byte(i) == 46 then -- 46 is the numeric ASCII code of the "." (.) (dot) character.
        extension = file_name:sub(i + 1, -len)
        break
      end
    end
  end

  return extension
end

-- Returns true if the given file exists, false otherwise.
downpour.ioutils.file["exists"] = function (name)
  _checks("string")

  local r = io.open(name, "rb")

  if r ~= nil then
    r:close()
    return true
  end

  return false
end

-- Returns the size of a file, which will be divided with factor. The returned result is bytes
-- and the factor by default is 1. Thus, passing a factor of 1024 will return the result as KBs, because, for example, 1024 bytes
-- divided by 1024 is 1 KB.
downpour.ioutils.file["size"] = function (file, factor)
  _checks("string", "uint64|nil")
  
  local handle, handle_exception = io.open(file, "rb")

  if handle_exception then
    log.write("[!] - downpour.ioutils.file.size(): Cannot open %s to measure the size. (reason: %s)", file, tostring(handle_exception))
    return -1
  end

  handle:seek("set", 0)
  local size = handle:seek("end")
  handle:close()

  return size / (factor or 1)
end

local _copy_internal_fast = function (src, dest, fsrc, fdest, bsize)
  _checks("string", "string", "string", "string", "uint64|nil")

  local src_handle, src_exception = io.open(src, fsrc)
  local dest_handle, dest_exception = io.open(dest, fdest)

  if (src_exception ~= nil) or (dest_exception ~= nil) then
    return false
  end

  bsize = (bsize or 8) * 1024

  while true do
    local buffer_data = src_handle:read(bsize)
    if not buffer_data then break end

    dest_handle:write(buffer_data)
  end

  src_handle:close()
  dest_handle:close()

  return true
end

local _copy_internal = function (src, dest, fsrc, fdest, bsize)
  _checks("string", "string", "string", "string", "uint64|nil")

  local src_handle, src_exception = io.open(src, fsrc)
  local dest_handle, dest_exception = io.open(dest, fdest)

  if src_exception ~= nil then
    log.write("[!] - _copy_internal(): Cannot open source file %s for copying data. (reason: %s)", src, tostring(src_exception))
    return false
  end

  if dest_exception ~= nil then
    log.write("[!] - _copy_internal(): Cannot create destination file %s for writing data. (reason: %s)", dest, tostring(dest_exception))
    return false
  end

  bsize = (bsize or 8) * 1024

  while true do
    local buffer_data = src_handle:read(bsize)
    if not buffer_data then break end

    dest_handle:write(buffer_data)
  end

  src_handle:close()
  dest_handle:close()

  return true
end

-- Copies a file (copy()) or a binary file (binary_copy()) into another one, overwriting the
-- destination file. On Windows systems, you may want to use copy() for ordinary files and copy_binary()
-- for binary files, but in Linux-based systems you can call  copy() for both file types as Linux doesn't
-- distinguish between file types.
downpour.ioutils.file["copy"] = function (src, dest, bsize)
  return _copy_internal(src, dest, "r", "w+", bsize)
end

downpour.ioutils.file["copy_binary"] = function (src, dest, bsize)
  return _copy_internal(src, dest, "rb", "w+b", bsize)
end

downpour.ioutils.file["copy_binary_fast"] = function (src, dest, bsize)
  return _copy_internal_fast(src, dest, "rb", "w+b", bsize)
end

-- Recursively scans a folder and lists all files that matches a certain extension. The second parameter can be omitted to
-- perform a full scan. Additionally, the third parameter specifies a user-made function which takes one argument to process
-- the scanned file. (i. e., removing the files that matches a certain extension while iterating through the list.)
--
-- get_list*() comes in two flavours:
--   get_list_unpack(), which scans for and returns two tables, one containing a list of found files and the other contains a list of found directories.
--   get_list_pack(), which does the same as get_list_unpack(), but it returns a merged list instead (and thus returns only one table). It uses get_list_unpack() internally.
downpour.ioutils.file["get_list_unpack"] = function (path, extensions, file_functor, folder_functor)
  _checks("string", "string|nil", "function|nil", "function|nil")

  if path == "" then
    return {}, {}, 0, 0
  end
  
  local last_character = path:byte(#path)
  if last_character ~= 47 and last_character ~= 92 then -- "\\" and "/", respectively. Append the "/" character if the last character of path does not contain either "\\" or "/".
    path = path .. "/"
  end

  extensions = extensions or '*'
  local ext_exists = extensions ~= '*'
  local dir_stack, ext_stack = {path}, {}
  local file_stack, directory_stack = {}, {}

  -- Parses out the extension list (separated with the semicolon ';' sign).
  -- This aids in parsing a directory while selecting files with multiple extensions.
  if ext_exists then
    ext_stack = downpour.ioutils.stringutils.split(extensions, ';')
  end

  -- Emulate the recursive feature that is normally found in functions like directory traversal,
  -- by creating a parameter stack and push parameters into it.
  -- Apparently because recursive benefits nothing but puts burden into the internal stack, and most implementations
  -- resort to the stack anyway.
  while #dir_stack > 0 do
    -- Pops the top frame of the stack, and pass it to current_dir.
    local current_dir = tostring(dir_stack[#dir_stack])
    dir_stack[#dir_stack] = nil

    log.write("[_] - downpour.ioutils.file.get_list_unpack(): Processing %s...", current_dir)

    -- Processes the current stack frame.
    for file in lfs.dir(current_dir) do
      if file ~= "." and file ~= ".." then
        local file_name = current_dir .. file
        local file_mode = lfs.attributes(file_name, "mode")

        log.write("[_] - downpour.ioutils.file.get_list_unpack(): Processing file %s (of type %s) in (sub) directory %s...", file_name, file_mode, current_dir)

        if file_mode == "file" then -- If the current "file" is an actual file, then push it to the file stack.
          if ext_exists then
            if downpour.ioutils.stringutils.match_table(downpour.ioutils.file.get_ext(file_name), ext_stack, #ext_stack) then
              file_stack[#file_stack + 1] = tostring(file_name)

              if file_functor ~= nil then
                file_functor(file_name)
              end
            end
          else
            file_stack[#file_stack + 1] = tostring(file_name)

            if file_functor ~= nil then
              file_functor(file_name)
            end
          end
        elseif file_mode == "directory" then -- If it's a directory, then push the directory into the directory stack, so we can have another folder to process.
          local fn = file_name .. '/'
          dir_stack[#dir_stack + 1] = fn

          -- Additionally, push the directory into our output directory stack.
          directory_stack[#directory_stack + 1] = fn

          if folder_functor then
            folder_functor(fn)
          end
        end
      end
    end
  end

  return file_stack, directory_stack, #file_stack, #directory_stack
end

downpour.ioutils.file["get_list_pack"] = function (path, extensions, functor)
  local files, directories, _, _ = downpour.ioutils.file.get_list_unpack(path, extensions, functor)
  local table = {}

  for _, directory in pairs(directories)  do table[#table + 1] = directory end
  for _, file in pairs(files) do table[#table + 1] = file end

  return table
end

downpour.ioutils.file["get_list"] = function (path, ext, func)
  return downpour.ioutils.file.get_list_pack(path, ext, func)
end

-- Clones/mirrors the whole directory hierarchy inside src to dest, including files and subfolders inside src.
-- Both the source directory and the destination directory must exist.
downpour.ioutils.file["clone"] = function (src, dest)
  _checks("string", "string")

  local sb, db = src:byte(#src), dest:byte(#dest)
  if sb ~= 92 and sb ~= 47 then src = src .. "/" end
  if db ~= 92 and db ~= 47 then dest = dest .. "/" end

  local file_table, dir_table, _, _ = downpour.ioutils.file.get_list_unpack(src)

  for _, vdir in pairs(dir_table) do
    local _, pos = downpour.ioutils.stringutils.match(vdir, src)

    lfs.mkdir(dest .. vdir:sub(pos, #vdir - 1))
  end

  for _, vfile in pairs(file_table) do
    local _, pos =  downpour.ioutils.stringutils.match(vfile, src)

    downpour.ioutils.file.copy_binary(vfile, dest .. vfile:sub(pos, #vfile))
  end

  return true
end

return downpour.ioutils -- // downpour.ioutils = {}
