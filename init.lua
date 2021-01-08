local function GeneratePlane(center, width)
	local targetLocs = {}
	for ox = center.x - width, center.x + width, 1 do
		for oz = center.z - width, center.z + width, 1 do
			table.insert(targetLocs, {x=ox, y=center.y, z=oz})
		end
	end
	return targetLocs
end

local function GenerateEdges(center, tilt, width, height)
	local targetLocs = {}
	for oy = center.y + 1, center.y+height, 1 do
		local dy = oy-center.y
		for ox = center.x-width+dy*tilt, center.x+width-dy*tilt, 1 do
			table.insert(targetLocs, {x=ox, y=oy, z=center.z-width+dy*tilt})
			table.insert(targetLocs, {x=ox, y=oy, z=center.z+width-dy*tilt})
		end
		for oz = center.z-width+dy*tilt, center.z+width-dy*tilt, 1 do
			table.insert(targetLocs, {x=center.x-width+dy*tilt, y=oy, z=oz})
			table.insert(targetLocs, {x=center.x+width-dy*tilt, y=oy, z=oz})
		end
	end
	return targetLocs
end

local function GeneratePath(pos, dir, length)
	local targetLocs = {}
	for i = 1, length do
		table.insert(targetLocs, {x=pos.x+dir.x*i, y=math.floor(pos.y), z=pos.z+dir.z*i})
	end
	return targetLocs
end

local function ClearBlock(pos, width, height)
	local targetLocs = {}
	for oy = pos.y, pos.y+height do
		for ox = pos.x-width, pos.x+width do
			for oz = pos.z-width, pos.z+width do
				table.insert(targetLocs, {x=ox, y=oy, z=oz})
			end
		end
	end
	return targetLocs
end

local function PopulateLayer(pos, yoffset, radius, count)
	local targetLocs = {}
	for i = 1, 100 do
		dx = (math.random()*2-1) * radius
		dy = (math.random()*2-1) * radius
		local target = {x=pos.x+dx, y=pos.y+yoffset, z=pos.z+dz}
		if minetest.get_node(target).name ~= "air" then
			table.insert(targetLocs, target)
		end
	end
	return targetLocs
end

local function ternary(cond, T, F)
    if cond then return T else return F end
end

minetest.register_chatcommand("fn", {
    func = function(name, params)
        print("Name: "..name)
        print("Params: "..params)
		if params:sub(0,2) == "ds" and params:len() > 3 then
			local otherName = params:sub(4)
            print(name.." challenges "..otherName.."for a duel inside Death Space!")
            -- Get player location
			local pos = minetest.get_player_by_name(name):getpos()
			-- Calculate reference position
			local heightOffset = 45 -- Height offset from current player location
			local newPos = {x=math.ceil(pos.x), y=math.ceil(pos.y)+heightOffset, z=math.ceil(pos.z)}
			-- Generate base area
			local width = 35
			local targetLocs = GeneratePlane(newPos, width)
			minetest.bulk_set_node(targetLocs, {name="basenodes:gravel"})
			-- Generate lava base
			local baseHeight = 5
			targetLocs = GenerateEdges(newPos, -1, width, baseHeight)
			minetest.bulk_set_node(targetLocs, {name="basenodes:gravel"})
			-- Generate edge
			local surrondingHeight = 25
			targetLocs = GenerateEdges({x=newPos.x, y=newPos.y+baseHeight, z=newPos.z}, 1, width+baseHeight, surrondingHeight)
			minetest.bulk_set_node(targetLocs, {name="basenodes:gravel"})
			-- Generate lava
			targetLocs = GeneratePlane({x=newPos.x, y=newPos.y+1, z=newPos.z}, width)
			minetest.bulk_set_node(targetLocs, {name="basenodes:lava_source"})
			targetLocs = GeneratePlane({x=newPos.x, y=newPos.y+2, z=newPos.z}, width+1)
			minetest.bulk_set_node(targetLocs, {name="basenodes:lava_source"})
			targetLocs = GeneratePlane({x=newPos.x, y=newPos.y+3, z=newPos.z}, width+2)
			minetest.bulk_set_node(targetLocs, {name="basenodes:lava_source"})
			-- Generate Platforms
			local platformSize = 3
			local platformHeight = 10
			local p1Center = {x=newPos.x-width/2, y=newPos.y+platformHeight, z=newPos.z}
			local p2Center = {x=newPos.x+width/2, y=newPos.y+platformHeight, z=newPos.z}
			targetLocs = GeneratePlane(p1Center, platformSize)
			minetest.bulk_set_node(targetLocs, {name="basenodes:gravel"})
			targetLocs = GeneratePlane(p2Center, platformSize)
			minetest.bulk_set_node(targetLocs, {name="basenodes:gravel"})
			-- Teleport Players
			local p1 = minetest.get_player_by_name(name)
			local p2 = minetest.get_player_by_name(otherName)
			p1:set_pos({x=p1Center.x, y=p1Center.y+2, z=p1Center.z})
			p2:set_pos({x=p2Center.x, y=p2Center.y+2, z=p2Center.z})
			-- Drop some equipments to other player
			local dir = p2:get_look_dir()
			local p2p = p2:get_pos()
			local itemPos = {x=p2p.x+dir.x*2, y=p2p.y+1, z=p2p.z+dir.z*2}
			minetest.add_item(itemPos, "basetools:pick_steel")
		elseif params:sub(0,4) == "path" and params:len() > 5 then
			local values = params:sub(6)
			-- Get current location
			local pos = minetest.get_player_by_name(name):getpos()
			-- Get look direction on horizontal plane
			local dir = minetest.get_player_by_name(name):get_look_dir()
			dir.y = 0
			-- Generate nodes
			local _,_, length, blockname = values:find("^([+-]?%d+)%s+([+-]?%S+)%s*$")
			local targetLocs = GeneratePath(pos, dir, tonumber(length))
			minetest.bulk_set_node(targetLocs, {name=ternary(blockname == "default", "basenodes:gravel", blockname)})
		elseif params:sub(0,6) == "summon" and params:len() > 7 then
			local otherName = params:sub(8)
			local pos = minetest.get_player_by_name(name):get_pos()
			minetest.get_player_by_name(otherName):set_pos(pos)
        elseif params:sub(0,4) == "grow" and params:len() > 5 then
			local values = params:sub(6)
			-- Get current position
			local pos = minetest.get_player_by_name(name):getpos()
			pos.y = math.floor(pos.y)
			-- Get radius and name
			local _,_, offset, radius, blockname, count = values:find("^([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%S+)%s+([+-]?%d+)%s*$")
			local targetLocs = PopulateLayer(pos, tonumber(offset), tonumber(radius), tonumber(count))
			minetest.bulk_set_node(targetLocs, {name=blockname})
		elseif params:sub(0,3) == "clr" and params:len() > 4 then
			local values = params:sub(5)
			-- Get current position
			local pos = minetest.get_player_by_name(name):getpos()
			pos.y = math.floor(pos.y)
			-- Get radius and height
			local _,_, radius, height = values:find("^([+-]?%d+)%s+([+-]?%d+)%s*$")
			if radius > 50 then
				print("Clearance area is too large, this might cause issue with inactive blocks.")
			else
				local targetLocs = ClearBlock(pos, tonumber(radius), tonumber(height))
				minetest.bulk_set_node(targetLocs, {name="air"})
			end
        else
            print([[
	Force of Nature commands pack: 
		- /fn help - print available chat commands.
		- /fn ds playerName - Death Space!
		- /fn path length blockname - Generate path of a given block, "default" blockname to gravel.
		- /fn grow offset radius blockname count - Grow blocks naturally, default bamboo.
		- /fn clr radius height - Clear a clearing in a square region.
		- /fn summon playerName - Summons a player close to you.
		]])
        end
    end
})

minetest.register_chatcommand("get_node_below", {
    func = function(name, params)
        local pos = minetest.get_player_by_name(name):getpos()
        pos.y = pos.y - 1
        local node = minetest.get_node(pos)
        print(node.name)
    end
})

--[[Reference Snippets:
+ Parse parameters
local _,_,offset,radius,blockname,count = params:find("^([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%S+)%s+([+-]?

+ Get block name
local pos = minetest.get_player_by_name("singleplayer"):get_pos()
pos.y = pos.y - 15
local node = minetest.get_node(pos)
print(dump(node))
]]