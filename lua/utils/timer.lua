local M = {}

-- better context or something
local title = "Music Player (Spotify)"
local uv = vim.loop
local polling_interval = 5 -- seconds
local timer = nil

M.start_polling = function(cb)
	if timer then
		M.stop_polling()
	end
	timer = uv.new_timer()
	if timer ~= nil then
		timer:start(0, polling_interval * 1000, function()
			cb()
		end)
		vim.notify("Started polling for song changes", vim.log.levels.INFO, { title = title })
	end
end

function M.stop_polling()
	if timer then
		timer:stop()
		timer:close()
		timer = nil
		vim.notify("Stopped polling for song changes", vim.log.levels.INFO, { title = title })
	end
end

return M
