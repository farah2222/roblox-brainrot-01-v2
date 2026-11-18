-- Brainrot Rumble: money formatting, shared by server and client so the
-- HUD, the floating labels and the popups always spell a number the same way.

local MoneyFormat = {}

-- $1,240 — whole dollars with commas.
function MoneyFormat.Cash(amount)
	local n = math.floor(amount)
	local text = tostring(n)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

-- $1.2K, $3.4M — short form for rates and labels.
function MoneyFormat.Short(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(math.floor(amount))
	end
end

-- 75s -> "1:15". Seconds as a clock.
function MoneyFormat.Clock(seconds)
	local s = math.max(0, math.floor(seconds))
	local minutes = math.floor(s / 60)
	local rest = s % 60
	if rest < 10 then
		return minutes .. ":0" .. rest
	end
	return minutes .. ":" .. rest
end

return MoneyFormat
