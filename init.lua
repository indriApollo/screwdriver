local function nextrange(x, max)
	x = x + 1
	if x > max then
		x = 0
	end
	return x
end

local function read_wear_user()
	--read wear from file
	local wear_set_by_user
	local mod_path = minetest.get_modpath("screwdriver")
	local conf_file = io.open(mod_path.."/screwdriver.conf", "r")
	    if conf_file == nil then
	          --file does not exist or can't be read
	      conf_file = io.open(mod_path.."/screwdriver.conf", "a")
	      conf_file:write("wear_set_by_user = 300")  --write a default value
	      wear_set_by_user = 300

	    else
	    	conf_file:seek(set,19)
	    	wear_set_by_user = tonumber(conf_file:read("*all"))
		      if wear_set_by_user == nil or wear_set_by_user < 0 or wear_set_by_user > 65535 then
		          conf_file = io.open(mod_path.."/screwdriver.conf", "w")
		          conf_file:write("wear_set_by_user = 300")   --write a default value
		          wear_set_by_user = 300
		      end
	      
	    end
	io.close(conf_file)

	return wear_set_by_user
end

-- Handles rotation
local function screwdriver_handler(itemstack, user, pointed_thing, mode, wear_set_by_user)
	if pointed_thing.type ~= "node" then
		return
	end

	local pos = pointed_thing.under
	local keys = user:get_player_control()
	local player_name = user:get_player_name()

	if minetest.is_protected(pos, user:get_player_name()) then
		minetest.record_protection_violation(pos, user:get_player_name())
		return
	end

	local node = minetest.get_node(pos)
	local ndef = minetest.registered_nodes[node.name]
	if not ndef or not ndef.paramtype2 == "facedir" or
			(ndef.drawtype == "nodebox" and
			not ndef.node_box.type == "fixed") or
			node.param2 == nil then
		return
	end

	-- Set param2
	local n = node.param2
	local axisdir = math.floor(n / 4)
	local rotation = n - axisdir * 4
	if mode == 1 then
		n = axisdir * 4 + nextrange(rotation, 3)
	elseif mode == 3 then
		n = nextrange(axisdir, 5) * 4
	end
	
	node.param2 = n
	minetest.swap_node(pos, node)

	local item_wear = tonumber(itemstack:get_wear())
	item_wear = item_wear + wear_set_by_user
	if item_wear > 65535 then
		itemstack:clear()
		return itemstack
	end
	itemstack:set_wear(item_wear)
	return itemstack
end

-- Screwdriver

local wear = read_wear_user()

minetest.register_tool("screwdriver:screwdriver", {
	description = "Screwdriver (left-click rotates face, right-click rotates axis)",
	inventory_image = "screwdriver.png",
	on_use = function(itemstack, user, pointed_thing)
		screwdriver_handler(itemstack, user, pointed_thing, 1, wear)
		return itemstack
	end,
	on_place = function(itemstack, user, pointed_thing)
		screwdriver_handler(itemstack, user, pointed_thing, 3, wear)
		return itemstack
	end,
})


minetest.register_craft({
	output = "screwdriver:screwdriver",
	recipe = {
		{"default:steel_ingot"},
		{"group:stick"}
	}
})

-- Compatibility with original mod
minetest.register_alias("screwdriver:screwdriver1", "screwdriver:screwdriver")
minetest.register_alias("screwdriver:screwdriver2", "screwdriver:screwdriver")
minetest.register_alias("screwdriver:screwdriver3", "screwdriver:screwdriver")
minetest.register_alias("screwdriver:screwdriver4", "screwdriver:screwdriver")