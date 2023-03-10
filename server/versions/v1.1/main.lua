version = 'v1.1'

print(version)

local fs = love.filesystem

local function copy(src, dst)
  if fs.getInfo(src, 'file') then
    print('Copying '..src..' to '..dst)
    fs.write(dst, fs.read(src))
  elseif fs.getInfo(src, 'directory') then
    fs.createDirectory(dst)
    for _, item in ipairs(fs.getDirectoryItems(src)) do
      copy(src..'/'..item, dst..'/'..item)
    end
  end
end

local function update()
  print('Updating')
  local http = require 'socket.http'
  local address = 'http://127.0.0.1:5000/diff/'..version
  print('Sending request to '..address)
  local body, code, headers, status = http.request(address)
  if not body then
    print('Error: '..code)
    return
  end
  print('Response code: '..code)
  if code ~= 200 then
    print('No new version')
    return
  end
  fs.write('update.zip', body)
  fs.mount('update.zip', 'update')
  copy('update/code', 'code')
  if fs.getInfo('update/removed_file.txt', 'file') then
    print('Removing files')
    for line in fs.lines('update/removed_file.txt') do
      fs.remove(line)
    end
  end
  fs.unmount('update.zip')
  fs.remove('update.zip')
  print('Restarting')
  for name, func in pairs(package.loaded) do
    if name:sub(1, 5) == 'code.' then
      package.loaded[name] = nil
    end
  end
  require 'code.main'
end

update()