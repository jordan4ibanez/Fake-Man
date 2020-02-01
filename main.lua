--create quadrants (maybe 2x2) and build the map made of that

--optimize pos[1] pos[2] into pos = {1,2}

--make ghosts keep moving in direction until finding another direction to go in ( check not current direction every time they reach a new tile)

--fill in the little chunks around the spawnpit so players don't get stuck



function love.load()

	moonshine = require 'moonshine'	
	effect = moonshine(moonshine.effects.crt)--.chain(moonshine.effects.crt)
	--effect.scanlines.thickness = 1
	
	effect.crt.feather = 0.01
	effect.crt.distortionFactor = {1.05,1.05}
	
	
	love.window.setMode(800, 800, {resizable=true, vsync=false, minwidth=400, minheight=400})
	--love.graphics.setDefaultFilter("nearest", "nearest", 0 )
	
	joysticks = love.joystick.getJoysticks()
    joystick = joysticks[1]
	
	--put this here so mapgen can use it
	level = 1
	
	Grid = require ("jumper.grid") -- The grid class
	Pathfinder = require ("jumper.pathfinder") -- The pathfinder class
	require("maps")
	require("helpers")
	load_textures()
	require("rendering")
	math.randomseed( os.time() )
	score = 0
	
	movementsound = love.audio.newSource("sounds/move1.ogg", "static")
	pickup = love.audio.newSource("sounds/pickup.ogg", "static")
	die = love.audio.newSource("sounds/die.ogg", "static")
	new = love.audio.newSource("sounds/new.ogg", "static")
	scrambled = love.audio.newSource("sounds/scrambled.ogg", "static")
	enemy = love.audio.newSource("sounds/enemy.ogg", "static")
	lose = love.audio.newSource("sounds/lose.ogg", "static")


	poweruptimer = 0
	lives = 10

	mapsize = 21 --make this odd
	tilesize = 800/(mapsize+2)
	scale = tilesize / 32
	
	map = {}
	map_generate()
		
	dir = {0,0}
	dirbuffer={0,0}
			
	pause = false
	debug = false
	
	hit_timer = 0 --this is used for when the player gets hit by demon
end

function love.update(dt)
	if lives > 0 then
	if pause == false then
		if hit_timer == 0 then
			input()
			input_joystick()
		
			if poweruptimer > 0 then
				poweruptimer = poweruptimer - dt
				if poweruptimer < 0 then
					poweruptimer = 0
				end
			end
			--move the demons
			ai_move(dt)

			--move the player
			player_move()
		else
			hit_timer = hit_timer - dt
			if hit_timer <= 0 then
				hit_timer = 0
			end
		end
	end
	end
end

--a function for collision
function collide(maptile)
	if maptile == 1 or maptile == 4 or maptile == 5 then
		return(true)
	end
end

local speedbuffer = 8 -- this controls the speed of the player (lower is slower
function player_move()	
	--check everything when on center of map section
	if pos[1] == realpos[1] and pos[2] == realpos[2] then
		--add this to be a "speed buffer" so that the player doesn't go off center of the tiles
		
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
		
		if collide(map[pos[2]+dir[2]][pos[1]+dir[1]]) then
		
			if not dirbuffer then --regular stop
				dir = {0,0}
			end
							
			if dirbuffer and collide(map[pos[2]+dirbuffer[2]][pos[1]+dirbuffer[1]]) then
				--try to hold buffer
				if collide(map[pos[2]+olddir[2]][pos[1]+olddir[1]]) then
					dir = {0,0}
				else
					dir = olddir
				end
			end
		end
		if map[realpos[2]][realpos[1]] == 2 then --collect points
			map[realpos[2]][realpos[1]] = 0 	
			score = score + 100
			pellets = pellets - 1
			--next level
			if pellets == 0 then
				poweruptimer = 0
				if debug == false then
					hit_timer = 5.5
					level = level + 1
				else
					level = level + 1
					map_generate()
				end
			end
		end
		if map[realpos[2]][realpos[1]] == 3 then --power up
			pickup:play()
			poweruptimer = poweruptimer + 5 --let them stack
			map[realpos[2]][realpos[1]] = 0 
		end

	end
	
	pos[1] = pos[1] + (dir[1]/speedbuffer)
	pos[2] = pos[2] + (dir[2]/speedbuffer)
	realpos = {math.floor(pos[1]),math.floor(pos[2])}
end

--player input
function input(dt)
	--temporarily store the direction to do collision checks
	if love.keyboard.isDown('up') and realpos[2] > 1 then
		dirbuffer={0,-1}
	elseif love.keyboard.isDown('down') and realpos[2] < mapsize then
		dirbuffer={0,1}
	elseif love.keyboard.isDown('left') and realpos[1] > 1 then
		dirbuffer={-1,0}
	elseif love.keyboard.isDown('right') and realpos[1] < mapsize then
		dirbuffer={1,0}
	end
end
function input_joystick()
	if not joystick then return end
 
 
	--temporarily store the direction to do collision checks
	if joystick:isGamepadDown('dpup') and realpos[2] > 1 then
		dirbuffer={0,-1}
	elseif joystick:isGamepadDown('dpdown') and realpos[2] < mapsize then
		dirbuffer={0,1}
	elseif joystick:isGamepadDown('dpleft') and realpos[1] > 1 then
		dirbuffer={-1,0}
	elseif joystick:isGamepadDown('dpright') and realpos[1] < mapsize then
		dirbuffer={1,0}
	end
end

function love.keypressed(key)
	local oldpos1 = pos[1]
	local oldpos2 = pos[2]
	
	if key == 'escape' then
		love.event.quit()
	end
	if key == 'f4' then
		debug=not debug
	end
	if key == 'f5' then
		map_generate()
		hit_timer = 0
	end
	if key == 'f6' then
		calculate_game_scale(mapsize)
	end
	if key == "space" then
		pause = not pause
	end
end

function ai_pathfind(dnumber)
	--for dnumber,data in pairs(demons) do
	local data = demons[dnumber]
	
	if data and data.realpos[1] and data.realpos[2] then
		--delete path to save calculations
		if poweruptimer > 0 then
			demons[dnumber].path = {}
		else
			--print(dump(map))

			-- Creates a grid object
			local grid = Grid(map) 
			-- Creates a pathfinder object using Jump Point Search
			
			local walkable = function(v)
				if v == 1 or v == 4 then return(false) else return(true) end end
			
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
					table.insert(demons[dnumber].path, {node:getX(),node:getY()})
				end
			else
				demons[dnumber].path = 0
			end
		end
	end
	
end

--this controls the actual "ai" of the demons
function ai_move(dt)
	for dnumber,position in pairs(demons) do
		--demons counter timer
		if poweruptimer == 0 and demons[dnumber].timer > 0 then
			demons[dnumber].timer = demons[dnumber].timer - dt
		end

		if demons[dnumber].timer <= 0 and demons[dnumber].pos[1] == demons[dnumber].realpos[1] and demons[dnumber].pos[2] == demons[dnumber].realpos[2] then
			--only pathfind when centered on tile
			if poweruptimer == 0 and demons[dnumber].timer <= 0 then
				ai_pathfind(dnumber)
			end
			--move randomly if no path
			if poweruptimer > 0 then   -----------------------here
				local z = math.random(1,2)
				demons[dnumber].dir = {0,0}
				demons[dnumber].dir[z] = math.random(-1,1)
				--print(demons[dnumber].dir[z])
				--return to old pos "wall detection"
				if demons[dnumber].pos[1] + demons[dnumber].dir[1] < 1 or demons[dnumber].pos[2] + demons[dnumber].dir[2] < 1 or demons[dnumber].pos[1] + demons[dnumber].dir[1] > mapsize or demons[dnumber].pos[2] + demons[dnumber].dir[2] > mapsize or collide(map[demons[dnumber].pos[2] + demons[dnumber].dir[2]][demons[dnumber].pos[1] + demons[dnumber].dir[1]]) then
					demons[dnumber].dir[1] = 0
					demons[dnumber].dir[2] = 0
				end			
			elseif type(position.path) == "table" and table.getn(position.path) > 0 then
				--print(dump(position.path[2]))
				demons[dnumber].dir[1] = position.path[2][1]-demons[dnumber].pos[1]
				demons[dnumber].dir[2] = position.path[2][2]-demons[dnumber].pos[2]
			end
		end
		
		
		--check if collided with player
		local diff = {pos[1]-demons[dnumber].pos[1],pos[2]-demons[dnumber].pos[2]}
		--print(dump(diff[1]))
		local hitbox = 0.8
		if hit_timer == 0 and math.abs(diff[1]) <= hitbox and math.abs(diff[2]) <= hitbox then
			local center = math.floor(mapsize/2)
			if poweruptimer == 0 then
				--print(dump(diff))
				lives = lives - 1
				hit_timer = 10
				die:play()
				for test,test2 in pairs(demons) do
					demons[test].pos = {center+1,center+1}
					demons[test].path = {}
					demons[test].dir = {0,0}
					demons[test].timer = 5
				end
				break
			else
				demons[dnumber].pos = {center+1,center+1}
				demons[dnumber].path = {}
				demons[dnumber].dir = {0,0}
				demons[dnumber].timer = 5
				score = score + 10000
				enemy:stop()
				enemy:play()
			end				
		end

		demons[dnumber].pos[1] = demons[dnumber].pos[1] + (demons[dnumber].dir[1]/demonspeed)
		demons[dnumber].pos[2] = demons[dnumber].pos[2] + (demons[dnumber].dir[2]/demonspeed)
		demons[dnumber].realpos[1] = math.floor(demons[dnumber].pos[1])
		demons[dnumber].realpos[2] = math.floor(demons[dnumber].pos[2])
	end
	
end
