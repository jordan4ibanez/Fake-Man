--optimize pos[1] pos[2] into pos = {1,2}

--add in counter to count how many pellets and list on screen then put 

--make ghosts respawn

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
	die = love.audio.newSource("sounds/die.ogg", "static")
	new = love.audio.newSource("sounds/new.ogg", "static")
	scrambled = love.audio.newSource("sounds/scrambled.ogg", "static")
	enemy = love.audio.newSource("sounds/enemy.ogg", "static")


	poweruptimer = 0
	lives = 10

	mapsize = 25
	tilesize = 12
	scale = tilesize / 32
	
	map = {}
	map_generate()
		
	dir = {0,0}
	dirbuffer={0,0}
		
	panimation_update = 0
	
	pause = false
	
	hit_timer = 0 --this is used for when the player gets hit by demon
end

function love.update(dt)
	if pause == false then
	if hit_timer == 0 then
	if lives > 0 then
		if poweruptimer > 0 then
			poweruptimer = poweruptimer - dt
			if poweruptimer < 0 then
				poweruptimer = 0
			end
		end
		--move the demons
		ai_pathfind()
		ai_move()

		--move the player
		player_move()
	else
		love.event.quit()
	end
	else
		hit_timer = hit_timer - dt
		if hit_timer <= 0 then
			hit_timer = 0
		end
	end
	end
end


function player_move()	
	--check everything when on center of map section
	if pos[1] == realpos[1] and pos[2] == realpos[2] then
		pos[1] = math.floor(pos[1])
		pos[2] = math.floor(pos[2])
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
		end
		if map[realpos[2]][realpos[1]] == 2 then --collect points
			map[realpos[2]][realpos[1]] = 0 	
			score = score + 100
		end
		if map[realpos[2]][realpos[1]] == 3 then --power up
			pickup:play()
			poweruptimer = 5
			map[realpos[2]][realpos[1]] = 0 
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
	if key == "space" then
		pause = not pause
	end
end

function ai_pathfind()
	for dnumber,data in pairs(demons) do
		if data.realpos[1] and data.realpos[2] and data.realpos[1] ~= -1 and data.realpos[2] ~= -1 then
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
				local startx, starty = math.floor(data.realpos[1]),math.floor(data.realpos[2])
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
		if position[1] ~= -1 and position[2] ~= -1 and demons[dnumber].pos[1] == demons[dnumber].realpos[1] and demons[dnumber].pos[2] == demons[dnumber].realpos[2] then
		
			--move randomly if no path
			if poweruptimer > 0 then   -----------------------here
				local z = math.random(1,2)
				demons[dnumber].dir = {0,0}
				demons[dnumber].dir[z] = math.random(-1,1)
				--print(demons[dnumber].dir[z])
				--return to old pos "wall detection"
				if demons[dnumber].pos[1] + demons[dnumber].dir[1] < 1 or demons[dnumber].pos[2] + demons[dnumber].dir[2] < 1 or demons[dnumber].pos[1] + demons[dnumber].dir[1] > mapsize or demons[dnumber].pos[2] + demons[dnumber].dir[2] > mapsize or map[demons[dnumber].pos[2] + demons[dnumber].dir[2]][demons[dnumber].pos[1] + demons[dnumber].dir[1]] == 1 then
					demons[dnumber].dir[1] = 0
					demons[dnumber].dir[2] = 0
				end
			
			elseif type(position.path) == "table" and table.getn(position.path) > 0 then
				--print(dump(position.path[2]))
				demons[dnumber].dir[1] = position.path[2][1]-demons[dnumber].pos[1]
				demons[dnumber].dir[2] = position.path[2][2]-demons[dnumber].pos[2]
			end
			--stops ghosts from stacking in same position
			--for ynumber,yposition in pairs(demons) do
			--	if yposition[1] ~= -1 and yposition[2] ~= -1 and dnumber ~= ynumber then --don't check self
			--		if demons[dnumber][1] == demons[ynumber][1] and demons[dnumber][2] == demons[ynumber][2] then
			--			demons[dnumber][1] = aioldpos1
			--			demons[dnumber][2] = aioldpos2
			--		end
			--	end
			--end
		end
		demons[dnumber].pos[1] = demons[dnumber].pos[1] + (demons[dnumber].dir[1]/16)
		demons[dnumber].pos[2] = demons[dnumber].pos[2] + (demons[dnumber].dir[2]/16)
		demons[dnumber].realpos[1] = math.floor(demons[dnumber].pos[1])
		demons[dnumber].realpos[2] = math.floor(demons[dnumber].pos[2])
		
		--check if collided with player
		local diff = {pos[1]-demons[dnumber].pos[1],pos[2]-demons[dnumber].pos[2]}
		--print(dump(diff[1]))
		if diff[1] >= -0.9375 and diff[1] <= 0.9375 and diff[2] >= -0.9375 and diff[2] <= 0.9375 then
			if poweruptimer == 0 then
				lives = lives - 1
				hit_timer = 10
				die:play()
			else
				demons[dnumber].pos[1] = -1
				demons[dnumber].pos[2] = -1
				score = score + 10000
				enemy:play()
			end				
		end
	end
	
end

local mouth = false
local cycle_timer = 0
local cycle_stage = 2
local cycling_table = {{-1,0},{0,-1},{1,0},{0,1}}
local sound_played = false
local sound2_played = false
function love.draw()
	if pause == false then
	if hit_timer == 0 then
	panimation_update = panimation_update + 0.1
	--animate player with noise
	if dir[1] ~= 0 or dir[2] ~= 0 then
	if panimation_update >= 0.5 then
		movementsound:play()
		mouth = not mouth
		panimation_update = 0
	end
	end
	--the death animation
	else
		
		
		mouth = false
		if hit_timer > 6.6 then
			cycle_timer = cycle_timer + 0.1
			if cycle_timer >= 0.25 then
				cycle_timer = 0
				cycle_stage = cycle_stage + 1
				if cycle_stage > 4 then
					cycle_stage = 1
				end
				dir[1] = cycling_table[cycle_stage][1]
				dir[2] = cycling_table[cycle_stage][2]
			end
		else
			--it's a long sequence
			if hit_timer <= 5.2 and hit_timer > 4.5 and sound_played == false then
				new:play()
				sound_played = true
			end
			dir[1] = cycling_table[3][1]
			dir[2] = cycling_table[3][2]
			
			if hit_timer < 4.5 then
				map_generate()
				sound_played = false
			end
			
			if hit_timer < 4.5 and hit_timer > 4 and sound2_played == false then
				scrambled:play()
				sound2_played = true
			end
			
			if hit_timer < 3 and hit_timer > 2 then
				sound2_played = false
				sound_1played = false
				dir[1] = cycling_table[math.random(1,4)][1]
				dir[2] = cycling_table[math.random(1,4)][2]
			end
			
			
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
	if hit_timer == 0 then
	for dnumber,data in pairs(demons) do
		if data[1] ~= -1 and data[2] ~= -1 then
			--this is debug
			--print(dump(data.path))
			--draw path
			if type(data.path) == "table" then
				for count, node in ipairs(data.path) do
					love.graphics.draw(tileset.path, node[1]*tilesize, node[2]*tilesize,0,scale,scale)
				end
			end
			--print(data[1])
			--print(data[2])
			--print(data[1].."|"..data[2])
			
			if data.pos[1] and data.pos[2] then
				--don't draw if "dead"
				if data.pos[1] ~= -1 and data.pos[2] ~= -1 then
					if poweruptimer == 0 then
						love.graphics.draw(tileset.ai, data.pos[1]*tilesize, data.pos[2]*tilesize,0,scale,scale)
					else
						love.graphics.draw(tileset.aiscared, data.pos[1]*tilesize, data.pos[2]*tilesize,0,scale,scale)
					end
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
	else
		local width, height, flags = love.window.getMode( )
		love.graphics.draw(tileset.pause, (width/2)-64, (height/2)-16)
	end
end
