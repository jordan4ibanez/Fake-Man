--flip x and y when generating map to fix all other values ( x is first, which isn't correct for indexing, it should be y)

--try a smooth movement


--optimize pos[1] pos[2] into pos = {1,2}

function love.load()
	love.window.setMode(800, 600, {resizable=true, vsync=true, minwidth=400, minheight=300})

	Grid = require ("jumper.grid") -- The grid class
	Pathfinder = require ("jumper.pathfinder") -- The pathfinder class
	require("helpers")
	math.randomseed( os.time() )
	score = 0
	
	load_textures()
	movementsound = love.audio.newSource("sounds/move1.ogg", "static")
	pickup = love.audio.newSource("sounds/pickup.ogg", "static")

	poweruptimer = 0
	lives = 10

	mapsize = 25
	tilesize = 12
	scale = tilesize / 32
	
	map = {}
	map_generate()
		
	dir = {0,0}
	dirbuffer={0,0}
	
	gamespeed = 0.2
	
	aiupdate = 0
	panimation_update = 0
end

function love.update(dt)
	if lives > 0 then
		aiupdate = aiupdate + dt
		if poweruptimer > 0 then
			poweruptimer = poweruptimer - dt
			if poweruptimer < 0 then
				poweruptimer = 0
			end
		end
		--move the demons
		if aiupdate > gamespeed then
			ai_pathfind()
			ai_move()
			aiupdate = 0
		end
		--move the player
		player_move()
	else
		love.event.quit()
	end
end


function player_move()
	local oldpos1 = pos[1]
	local oldpos2 = pos[2]	
	
	--check everything when on center of map section
	if pos[1] == realpos[1] and pos[2] == realpos[2] then
		local olddir = {0,0}
		if dirbuffer then
			olddir = {dir[1],dir[2]}
			dir = {dirbuffer[1],dirbuffer[2]}
		end
		--map limit
		if (pos[1] + dir[1] < 1 or pos[2] + dir[2] < 1 or pos[1] + dir[1] > mapsize or pos[2] + dir[2] > mapsize) then
			if not dirbuffer then --regular stop
				dir = {0,0}
			end
			--try to hold buffer
			if pos[1] + olddir[1] < 1 or pos[2] + olddir[2] < 1 or pos[1] + olddir[1] > mapsize or pos[2] + olddir[2] > mapsize then
				dir = {0,0}
			else
				dir = olddir
			end
		end
		
		if map[pos[2]+dir[2]][pos[1]+dir[1]] == 1 then
		
			if not dirbuffer then --regular stop
				dir = {0,0}
			end
							
			if dirbuffer and map[pos[2]+dirbuffer[2]][pos[1]+dirbuffer[1]] == 1 then
				--try to hold buffer
				if map[pos[2]+olddir[2]][pos[1]+olddir[1]] == 1 then
					dir = {0,0}
				else
					dir = olddir
				end
			end
		elseif map[pos[2]][pos[1]] == 2 then --collect points
			map[pos[2]][pos[1]] = 0 	
			score = score + 100
		elseif map[pos[2]][pos[1]] == 3 then --power up
			pickup:play()
			poweruptimer = 5
			map[pos[2]][pos[1]] = 0 
		end

		for dnumber,data in pairs(demons) do
			if data[1] and data[2] and data[1] ~= -1 and data[2] ~= -1 then
				if data[1] == pos[1] and data[2] == pos[2] then
					if poweruptimer == 0 then
						--lives = lives - 1
						--pos[1] = math.random(1,mapsize)
						--pos[2] = math.random(1,mapsize)
					else
						demons[dnumber][1] = -1
						demons[dnumber][2] = -1
					end
				end
			end
		end
	end
	
	pos[1] = pos[1] + (dir[1]/8)
	pos[2] = pos[2] + (dir[2]/8)
	realpos = {math.floor(pos[1]),math.floor(pos[2])}
end

--player input
function love.keypressed(key)
	local oldpos1 = pos[1]
	local oldpos2 = pos[2]
	--temporarily store the direction to do collision checks
	if key == 'up' and realpos[2] > 1 then
		dirbuffer={0,-1}
	elseif key == 'down' and realpos[2] < mapsize then
		dirbuffer={0,1}
	elseif key == 'left' and realpos[1] > 1 then
		dirbuffer={-1,0}
	elseif key == 'right' and realpos[1] < mapsize then
		dirbuffer={1,0}
	end
	if key == 'escape' then
		love.event.quit()
	end
	if key == 'f5' then
		map_generate()
	end
	if key == 'f6' then
		calculate_game_scale(mapsize)
	end
end

function ai_pathfind()
	for dnumber,data in pairs(demons) do
		if data[1] and data[2] and data[1] ~= -1 and data[2] ~= -1 then
			--delete path to save calculations
			if poweruptimer > 0 then
				demons[dnumber].path = {}
			else
				--print(dump(map))

				-- Creates a grid object
				local grid = Grid(map) 
				-- Creates a pathfinder object using Jump Point Search
				
				local walkable = function(v) return v~=1 end
				
				local myFinder = Pathfinder(grid, 'ASTAR', walkable)

				myFinder:setMode('ORTHOGONAL')
				
				-- Define start and goal locations coordinates
				local startx, starty = data[1],data[2]
				local endx, endy = realpos[1],realpos[2]

				-- Calculates the path, and its length
				local path = myFinder:getPath(startx, starty, endx, endy)
				if path and path:getLength() > 0 then
					demons[dnumber].path = {}
					--demons[dnumber].path = path
					for node, count in path:nodes() do
						table.insert(data.path, {node:getX(),node:getY()})
					end
				else
					demons[dnumber].path = 0
				end
			end
		end
	end
end

--this controls the actual "ai" of the demons
function ai_move()
	for dnumber,position in pairs(demons) do
		if position[1] ~= -1 and position[2] ~= -1 then
			--remember old value
			local aioldpos1 = demons[dnumber][1]
			local aioldpos2 = demons[dnumber][2] 
			
			
			--move randomly if no path
			if poweruptimer > 0 then
				local z = math.random(1,2)
				demons[dnumber][z] = demons[dnumber][z] + math.random(-1,1)
						
				--return to old pos "wall detection"
				if demons[dnumber][1] < 1 or demons[dnumber][2]< 1 or demons[dnumber][1] > mapsize or demons[dnumber][2] > mapsize or map[demons[dnumber][2]][demons[dnumber][1]] == 1 then
					demons[dnumber][1] = aioldpos1
					demons[dnumber][2] = aioldpos2
				end
			
			elseif type(position.path) == "table" then
				--print(dump(position.path[2]))
				demons[dnumber][1] = position.path[2][1]
				demons[dnumber][2] = position.path[2][2]		
				--table.remove (position.path, 1)
			end
			--stops ghosts from stacking in same position
			for ynumber,yposition in pairs(demons) do
				if yposition[1] ~= -1 and yposition[2] ~= -1 and dnumber ~= ynumber then --don't check self
					if demons[dnumber][1] == demons[ynumber][1] and demons[dnumber][2] == demons[ynumber][2] then
						demons[dnumber][1] = aioldpos1
						demons[dnumber][2] = aioldpos2
					end
				end
			end
		end
	end
end

local mouth = false
function love.draw()
	panimation_update = panimation_update + 0.1
	--animate player with noise
	if dir[1] ~= 0 or dir[2] ~= 0 then
	if panimation_update >= 0.5 then
		movementsound:play()
		mouth = not mouth
		panimation_update = 0
	end
	end
	calculate_game_scale(mapsize)
	
	love.graphics.print("SCORE: "..score, 0, 0)
	if poweruptimer > 0 then
		love.graphics.print("POWER: "..poweruptimer, 300, 0)
	end
	love.graphics.print("LIVES: "..lives, 600,0)
	--render map
	for x=1,mapsize do
	for y=1,mapsize do
		if map[x][y] == 1 then
			love.graphics.draw(tileset.tile, y*tilesize, x*tilesize,0,scale,scale)
		elseif map[x][y] == 2 then
			love.graphics.draw(tileset.point, y*tilesize, x*tilesize,0,scale,scale)
		elseif map[x][y] == 3 then
			love.graphics.draw(tileset.powerup, y*tilesize, x*tilesize,0,scale,scale)
		end
	end
	end
	
	--draw ai
	for dnumber,data in pairs(demons) do
		if data[1] ~= -1 and data[2] ~= -1 then
			--this is debug
			--print(dump(data.path))
			--draw path
			--if type(data.path) == "table" then
			--	for count, node in ipairs(data.path) do
			--		love.graphics.draw(tileset.pathmarker, node[1]*tilesize, node[2]*tilesize,0,scale,scale)
			--	end
			--end
			--print(data[1])
			--print(data[2])
			--print(data[1].."|"..data[2])
			
			
			if data[1] and data[2] then
				--don't draw if "dead"
				if data[1] ~= -1 and data[2] ~= -1 then
					if poweruptimer == 0 then
						love.graphics.draw(tileset.ai, data[1]*tilesize, data[2]*tilesize,0,scale,scale)
					else
						love.graphics.draw(tileset.aiscared, data[1]*tilesize, data[2]*tilesize,0,scale,scale)
					end
				end
			end
		end
	end
	
	--fix flipping image to other tile
	local size0 = 0
	local size1 = dir[1]
	if dir[1] == 0 then size1 = 1 end
	if dir[1] == -1 then size0 = tilesize end
	
	local size2 = dir[2]
	if dir[2] == 1 then size2 = math.rad(90) elseif dir[2] == -1 then size2 = math.rad(-90) end
	--fix the rotation location
	local size3 = 0
	local size4 = 0
	if dir[2] == -1 then 
		size3 = 0
		size4 = tilesize
	elseif dir[2] == 1 then 
		size3 = tilesize
		size4 = 0
	end

	--animate mouth
	if mouth == true then
		love.graphics.draw(tileset.player_mouthclose, pos[1]*tilesize+size3+size0, pos[2]*tilesize+size4,size2,scale*size1,scale)
	else
		love.graphics.draw(tileset.player, pos[1]*tilesize+size3+size0, pos[2]*tilesize+size4,size2,scale*size1,scale)
	end

	love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end
