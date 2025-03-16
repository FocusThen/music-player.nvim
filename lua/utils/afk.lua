local M = {}

local afk_timer = nil
local afk_timeout = 5 * 60 * 1000 -- 5 minutes in milliseconds
local is_afk = false

M.reset_afk_timer = function(callback)
	if afk_timer then
		afk_timer:stop()
		afk_timer:close()
	end

	afk_timer = vim.uv.new_timer()
	if afk_timer then
		afk_timer:start(
			afk_timeout,
			0,
			vim.schedule_wrap(function()
				is_afk = true
				callback()
			end)
		)
	end
end

M.resume_afk = function(callback)
	if is_afk then
		is_afk = false
		callback()
	end
end

return M
