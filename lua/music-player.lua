local utils = require("utils.auth")
local M = {}

local API = "https://api.spotify.com/"
local currently = "https://api.spotify.com/v1/me/player/currently-playing"

M.setup = function()
	local encoded_client = utils.get_credentials(false)

	if not encoded_client then
		print("No credentials found. Please input your Spotify credentials.")
	end

	local logined_user = utils.login_with_credentials(encoded_client)
end

return M
