local utils = require("utils.auth")

local M = {}

M.setup = function()
	local encoded_client = utils.get_credentials(false)

	if not encoded_client then
		print("No credentials found. Please input your Spotify credentials.")
	end

	local logined_user = utils.login_with_credentials(encoded_client)

	utils.get_currently_playing(logined_user)
end

return M
