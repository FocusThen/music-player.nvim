local M = {
	saved_file_path = vim.fn.stdpath("config") .. "/music-player-credentials.json",
}

M.save_credentials = function(data, update)
	local mode = update and "w+" or "w"
	local file = io.open(M.saved_file_path, mode)

	if file then
		file:write(vim.json.encode(data))
		file:close()
		print("Saved credentials")
	else
		print("Failed to open file: " .. M.saved_file_path)
	end
end

M.read_credentials = function()
	local file = io.open(M.saved_file_path, "r")

	if not file then
		print("No saved credentials found.: " .. M.saved_file_path)
		return nil
	end

	local content = file:read("*a")
	file:close()

	return vim.json.decode(content)
end

return M
