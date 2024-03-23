function table:deepCopy()
       if type(self) ~= 'table' then return self end
       local res = setmetatable({}, getmetatable(self))
       for k, v in pairs(self) do res[table.deepCopy(k)] = table.deepCopy(v) end
       return res
end

local function matchCriteria(fn, criteria)
    local isArray = false
    local arrayMatch = false
    for k, v in pairs(criteria) do
        if math.type(k) ~= nil then
            isArray = true
            if fn.id == v then
                arrayMatch = true
                break
            end
        else
            if k == 'id' then
                if fn.id ~= v then return false end
            end
            if k == 'type' then
                if fn.type:match('^' .. v .. '$') == nil then return false end
            end
            if fn.meta[k] == nil then return false end
            if fn.meta[k]:match('^' .. v .. '$') == nil then return false end
        end
    end
    if isArray then return arrayMatch end
    return true
end

function findDevice(criteria)
    devices = lynx.getDevices()
    if math.type(criteria) ~= nil then
        for _, dev in ipairs(devices) do
            if dev.id == criteria then return dev end
        end
    elseif type(criteria) == 'table' then
        for _, dev in ipairs(devices) do
            if matchCriteria(dev, criteria) then return dev end
        end
    end
    return nil
end


function findFunction(criteria)
    if math.type(criteria) ~= nil then
        for _, fn in ipairs(functions) do
            if fn.id == criteria then return fn end
        end
    elseif type(criteria) == 'table' then
        for _, fn in ipairs(functions) do
            if matchCriteria(fn, criteria) then return fn end
        end
    end
    return nil
end


function findFunctions(criteria)
    local res = {}
    if type(criteria) == 'table' then
        for _, fn in ipairs(functions) do
            if matchCriteria(fn, criteria) then table.insert(res, fn) end
        end
    end
    return res
end

local topicRepetitions = {}
local topicFunction = {}
local edgeTrigger = {}

function handleTrigger(topic, payload, retained)
	local data = json:decode(payload)
	if topicRepetitions[topic] == nil then
		topicRepetitions[topic] = 0
	end
	if cfg.overOrUnder == "under" then
		if data.value < cfg.threshold then
			topicRepetitions[topic] = topicRepetitions[topic] + 1
		else
			topicRepetitions[topic] = 0
		end
	elseif cfg.overOrUnder == "over" then
		if data.value > cfg.threshold then
			topicRepetitions[topic] = topicRepetitions[topic] + 1
		else
			topicRepetitions[topic] = 0
		end
	end
	sendNotificationIfArmed(topic, data.value, cfg.overOrUnder)
end

function onStart()
	for i, fun in ipairs(cfg.trigger_functions) do
		local triggerFunction = findFunction(fun)
		local triggerTopic = triggerFunction.meta.topic_read

		-- Keep mapping between topic and function. In the case
		-- of two functions having the same topic the last one
		-- in this loop will be used.
		topicFunction[triggerTopic] = triggerFunction

		mq:sub(triggerTopic, 0)
		mq:bind(triggerTopic, handleTrigger)
	end
end

function sendNotificationIfArmed(topic, value, action)
	if cfg.notification_output == nil then return end

	local func = topicFunction[topic]
	local dev = findDevice(tonumber(func.meta.device_id))
	local repetitions = topicRepetitions[topic]
	local sent = edgeTrigger[topic]
	if repetitions > cfg.repetitions then
	    if sent then return end
		local payloadData = {
			value = value,
			action = action,
			firing = func.meta.name,
			unit = func.meta.unit,
			note = func.meta.note,
			func = func,
			device = dev,
			threshold = cfg.threshold
		}
		lynx.notify(cfg.notification_output, payloadData)
		edgeTrigger[topic] = true
	else
	    edgeTrigger[topic] = false
	end
end
