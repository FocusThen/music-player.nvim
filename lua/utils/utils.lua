local M = {}

M.build_authorization_url = function(client_id, redirect_uri)
	local base_url = "https://accounts.spotify.com/authorize"
	local params = {
		client_id = client_id,
		response_type = "code",
		redirect_uri = redirect_uri,
		scope = "user-read-currently-playing user-modify-playback-state",
	}
	local encoded_params = {}
	for k, v in pairs(params) do
		encoded_params[#encoded_params + 1] = k .. "=" .. vim.uri_encode(v)
	end

	return base_url .. "?" .. table.concat(encoded_params, "&")
end

M.open_browser = function(url)
	-- For macOS open.  Use "xdg-open" for Linux, "start" for Windows
	vim.fn.jobstart({ "open", url })
end

return M
