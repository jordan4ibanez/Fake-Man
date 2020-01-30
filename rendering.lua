local mouth = false
local cycle_timer = 0
local cycle_stage = 2
local cycling_table = {{-1,0},{0,-1},{1,0},{0,1}}
local sound_played = false
local sound2_played = false
local map_genned = true

function render()
	calculate_game_scale(mapsize)
	translate_graphics()
	--effect.resize((mapsize+2)*tilesize, (mapsize+2)*tilesize)
	
	--effect(function()
	if lives > 0 then
	if pause == false then
	if hit_timer == 0 then
	panimation_update = panimation_update + 0.1
	--animate player with noise
	if dir[1] ~= 0 or dir[2] ~= 0 then
	if panimation_update >= 0.5 then
		movementsound:play()
		mouth = not mouth
		panimation_update = 0
		map_genned = false
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
				sound_played = false
			end
			
			if hit_timer < 4.5 and hit_timer > 4 and sound2_played == false then
				scrambled:play()
				sound2_played = true
			end
			
			if hit_timer < 3 and hit_timer > 2 then
				sound2_played = false
				sound_1played = false
				--reset map
				if map_genned == false then
					map_genned = true
					map_generate()
				end
			end
		end
	end
	
	love.graphics.print("SCORE: "..score, 0, 0)
	if poweruptimer > 0 then
		love.graphics.print("POWER: "..poweruptimer, 300, 0)
	end
	love.graphics.print("LIVES: "..lives, 600,0)
	--render map
	if hit_timer == 0 then
		for x=1,mapsize do
		for y=1,mapsize do
			if map[x][y] == 1 then
				love.graphics.draw(tileset.tile, y*tilesize, x*tilesize,0,scale,scale)
			elseif map[x][y] == 2 then
				love.graphics.draw(tileset.point, y*tilesize, x*tilesize,0,scale,scale)
			elseif map[x][y] == 3 then
				love.graphics.draw(tileset.powerup, y*tilesize, x*tilesize,0,scale,scale)
			elseif map[x][y] == 4 then
				love.graphics.draw(tileset.pit, y*tilesize, x*tilesize,0,scale,scale)
			end
		end
		end
	elseif hit_timer <=  4.5 then
		--render glitches
		for x=1,mapsize do
		for y=1,mapsize do
			local randy = love.math.random(1,4)
			if randy == 1 then
				love.graphics.draw(tileset.tile, y*tilesize, x*tilesize,0,scale,scale)
			elseif randy == 2 then
				love.graphics.draw(tileset.point, y*tilesize, x*tilesize,0,scale,scale)
			elseif randy == 3 then
				love.graphics.draw(tileset.powerup, y*tilesize, x*tilesize,0,scale,scale)
			elseif randy == 4 then
				love.graphics.draw(tileset.pit, y*tilesize, x*tilesize,0,scale,scale)
			end
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
			if debug == true then
				if type(data.path) == "table" then
					for count, node in ipairs(data.path) do
						love.graphics.draw(tileset.path, node[1]*tilesize, node[2]*tilesize,0,scale,scale)
					end
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
	
	
	if hit_timer >  4.5 or hit_timer == 0 then
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
	end

	love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
	love.graphics.print("Pellets Remaining: "..tostring(pellets), 200, 10)
	love.graphics.print("Level: "..tostring(level), 400, 10)
	else
		local width, height, flags = love.window.getMode( )
		love.graphics.draw(tileset.pause, (width/2)-64, (height/2)-16)
	end
	else
		--game over - extra annoying
		local width, height, flags = love.window.getMode( )
		love.graphics.draw(tileset.gameover, (width/2)-64, (height/2)-16)
		lose:play()
	end
	--end)
end
