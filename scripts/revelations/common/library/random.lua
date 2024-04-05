return function()

---@generic V
---@param tbl V[]
---@param rng? RNG
---@return V
function REVEL.randomFrom(tbl, rng)
    if #tbl ~= 0 then
        return tbl[StageAPI.Random(1, #tbl, rng)]
    end
    error("REVEL.randomFrom | table empty", 2)
end

---Returns a random key using the weights in values
---@generic T
---@param args {[T]: number}
---@param rng? RNG
---@return T
function REVEL.WeightedRandom(args, rng)
    local weight_value = 0
    local iterated_weight = 1
    local isFloat = false
    for name, weight in pairs(args) do
        weight_value = weight_value + weight
        if weight % 1 ~= 0 then
            isFloat = true
        end
    end

	if weight_value > 0 then
		local random_chance
        if isFloat then
            random_chance = StageAPI.RandomFloat(1, weight_value + 1, rng)
        else
            random_chance = StageAPI.Random(1, weight_value, rng)
        end
		for name, weight in pairs(args) do
			iterated_weight = iterated_weight + weight
			if iterated_weight > random_chance then
				return name
			end
		end
	end
end

---@generic T
---@param tbl T[]
---@param rng? RNG
---@return T[]
function REVEL.Shuffle(tbl, rng)
    local len = #tbl
    for i = len, 2, -1 do
        local rand = StageAPI.Random(1, len, rng)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end

    return tbl
end

--- Returns a list with keys of args sorted
-- randomly, with higher weight (key's value)
-- items being more likely to be early
---@generic T
---@param args table<T, number>
---@param rng? RNG
---@return T[]
function REVEL.WeightedShuffle(args, rng)
    REVEL.Assert(args, "WeightedShuffle | args nil!", 2)

    -- Not the most optimized thing

    local randomValues = REVEL.flatmap(args, function (val, key, list)
        return {Item = key, R = StageAPI.RandomFloat(0, val, rng)}
    end)
    table.sort(randomValues, function (a, b)
        return a.R > b.R
    end)
    return REVEL.map(randomValues, function (val, key, list)
        return val.Item
    end)
end

---@generic T
---@param set {[T]: any}
---@param count? integer
---@return T
function REVEL.RandomFromSet(set, count)
    if not count then
        count = 0
        for _, _ in pairs(set) do
            count = count + 1
        end
    end

    if count > 0 then
        local randomId = math.random(count)
        local currentId = 1
        for value, _ in pairs(set) do
            currentId = currentId + 1
            if currentId > randomId then
                return value
            end
        end
    end
end

---@return 1 | -1
function REVEL.RandomSign()
    return (math.random() - 0.5 > 0) and 1 or -1
end

end