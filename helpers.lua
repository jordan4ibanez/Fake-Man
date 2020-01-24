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
	
	--reset players position for debug
	pos = {math.random(1,mapsize),math.random(1,mapsize)}
	
	--generate demons here for debug
	demons = {}
	demonnumber = 9
	for i = 1,demonnumber do
		demons[i] = {math.random(1,mapsize),math.random(1,mapsize),path={}}
	end
end
