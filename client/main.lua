local fs = love.filesystem
fs.setSymlinksEnabled(true)
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
if fs.getInfo('code/main.lua', 'file') then
else
  print('Copying prebuilt to code')
  copy('prebuilt', 'code')
end
require 'code.main'