--helps read tables
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

--generate a random map
function map_generate()
	map = {}

	for x = 1,mapsize do
	map[x]={}
	for y = 1,mapsize do
		local perlin = math.random() * math.random()
		map[x][y] = 0
		if perlin >= 0.45 then
			map[x][y] = 1
		else
			map[x][y]= 2
		end
		if perlin >= 0.9 then
			map[x][y] = 3
		end
	end
	end
	
	--create walls
	for x = 1,mapsize do
	for y = 1,mapsize do
		if (x == 1 or x == mapsize) or (y == 1 or y == mapsize) then
			map[x][y]=1
		end
	end
	end
	
	--reset players position for debug
	pos = {math.random(2,mapsize-1),math.random(2,mapsize-1)}
	realpos = {math.floor(pos[1]),math.floor(pos[2])}
	
	--generate demons here for debug
	demons = {}
	demonnumber = 1
	for i = 1,demonnumber do
		local dpos = {math.random(2,mapsize-1),math.random(2,mapsize-1)}
		demons[i] = {pos={dpos[1],dpos[2]},path={},realpos={dpos[1],dpos[2]},dir={0,0}} --change [1] [2] to pos = {1,2}
	end
end


--automate loading textures
function load_textures()
	tileset = {}
	local test = love.filesystem.getDirectoryItems("textures")
	for test,texture in ipairs(test) do
		tileset[string.gsub(texture, ".png", "")] = love.graphics.newImage("textures/"..texture)
	end
end

--rescales the map
function calculate_game_scale(mapsize1)
	local width, height, flags = love.window.getMode( )

	mapsize1 = mapsize1 + 1
	if height>=width then
		tilesize = width/mapsize1
	else
		tilesize = height/mapsize1
	end
	scale = tilesize / 32
	return({tilesize,scale})
end
