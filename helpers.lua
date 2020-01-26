--a helper for mapgen
function is_even(number)
	if (number % 2 == 0) then
		return(true)
	else
		return(false)
	end
end

--a function for collision
function collide(maptile)
	if maptile == 1 or maptile == 4 then
		return(true)
	end
end



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


--possibly leave out spaces for players to travel

function map_generate()
	map = {}
	
	pellets = 0

	--create the level base
	for x = 1,mapsize do
	map[x]={}
	for y = 1,mapsize do
		if x == 1 or x == mapsize or y == 1 or y == mapsize then
			map[x][y] = 1
		else
			map[x][y] = 2
		end
	end
	end
	--create the maze
	--[[
	for x = 1,mapsize-1 do
	for y = 1,mapsize-1 do
		local xp,yp = love.math.random(2,5),love.math.random(2,5)
		local xp2,yp2 = love.math.random(4,5),love.math.random(4,5)
		
		if x%xp==0 or y%yp==0 then
			map[x][y] = 1
		end
		if x%xp2==0 or y%yp2==0 then
			map[x][y] = 2
		end
		
	end
	end
	]]--
	for x = 1,mapsize-1 do
	for y = 1,mapsize-1 do
		local chunk = template[0]--[love.math.random(1,8)]
		if x % 3 == 0 and y % 3 == 0 then
			for xx,data in ipairs(chunk) do
				for yy,value in pairs(data) do
					map[xx+x-1][yy+y-1] = value
				end
			end
		end
	end
	end
	--create wall
	for x = 1,mapsize do
	for y = 1,mapsize do
		if x == 1 or x == mapsize or y == 1 or y == mapsize then
			map[x][y] = 1
		end
	end
	end
	
	local center = math.floor(mapsize/2)
	--make spawn pit
	local chunk = template.spawnpit
	for xx,data in ipairs(chunk) do
		for yy,value in pairs(data) do
			map[center-1+xx][center-1+yy]=value
		end
	end
	
	
	pellets = math.floor(pellets*0.5)
	
	--reset players position for debug
	pos = {center+1,center+3}
	realpos = {math.floor(pos[1]),math.floor(pos[2])}
	
	--generate demons here for debug
	demons = {}
	demonnumber = math.random(1,20)
	local dtimer = 0
	for i = 1,demonnumber do
		local dpos = {center+1,center+1}
		demons[i] = {pos={dpos[1],dpos[2]},path={},realpos={dpos[1],dpos[2]},dir={0,0},timer=dtimer}
		dtimer = dtimer + 0.5
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
