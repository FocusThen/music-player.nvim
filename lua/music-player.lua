local curl = require("plenary.curl")
local utils = require("utils.utils")
local utils_file = require("utils.file")

local title = "Music Player (Spotify)"

local M = {
	client_id = nil,
	client_secret = nil,
	b64_client = nil,
	auth_code = nil,
	refresh_token = nil,
	access_token = nil,
	redirect_url = "http://localhost",
}

M.setup = function()
	-- nil
end

M.authorize = function()
	local credentials = utils_file.read_credentials()

	if credentials then
		M.access_token = credentials.access_token
		M.refresh_token = credentials.refresh_token
		M.b64_client = credentials.b64_client
		vim.notify("Tokens retrieved successfully!", vim.log.levels.INFO, { title = title })
		return
	end

	M.client_id = vim.fn.input("Enter your Spotify Client ID: ")
	M.client_secret = vim.fn.inputsecret("Enter your Spotify Client Secret: ")

	local auth_url = utils.build_authorization_url(M.client_id, M.redirect_url)
	print("Opening browser for Spotify authorization...")
	utils.open_browser(auth_url)
	print("Please authorize the application in your browser.")
	print("After authorization, copy the 'code' from the redirected URL and paste it below.")
	vim.ui.input({ prompt = "Enter authorization code: " }, function(input)
		M.auth_code = input
		M.get_tokens()
	end)
end

M.get_tokens = function()
	if not M.auth_code then
		vim.notify("Authorization code is missing.", vim.log.levels.ERROR, { title = title })
		return
	end

	local url = "https://accounts.spotify.com/api/token"
	local body = {
		grant_type = "authorization_code",
		code = M.auth_code,
		redirect_uri = M.redirect_url,
	}
	local t_encoded_body = {}
	for k, v in pairs(body) do
		t_encoded_body[#t_encoded_body + 1] = k .. "=" .. vim.uri_encode(v)
	end
	local s_encoded_body = table.concat(t_encoded_body, "&")

	M.b64_client = vim.base64.encode(M.client_id .. ":" .. M.client_secret)
	local headers = {
		["Content-Type"] = "application/x-www-form-urlencoded",
		["Authorization"] = "Basic " .. M.b64_client,
	}

	local response, err = curl.request({
		url = url,
		method = "POST",
		body = s_encoded_body,
		headers = headers,
	})

	if err then
		vim.notify("Error: " .. err, vim.log.levels.ERROR, { title = title })
	end

	if response.status == 200 then
		local data = vim.json.decode(response.body)
		M.access_token = data.access_token
		M.refresh_token = data.refresh_token
		vim.notify("Tokens retrieved successfully!", vim.log.levels.INFO, { title = title })

		-- Save
		utils_file.save_credentials({
			access_token = M.access_token,
			refresh_token = M.refresh_token,
			b64_client = M.b64_client,
		})
	else
		vim.notify("Failed to retrieve tokens: " .. response.body, vim.log.levels.ERROR, { title = title })
	end
end

M.fn_refresh_token = function()
	if not M.refresh_token then
		vim.notify("Refresh token is missing.", vim.log.levels.ERROR, { title = title })
		return
	end

	local url = "https://accounts.spotify.com/api/token"
	local body = {
		grant_type = "refresh_token",
		refresh_token = M.refresh_token,
	}

	local t_encoded_body = {}
	for k, v in pairs(body) do
		t_encoded_body[#t_encoded_body + 1] = k .. "=" .. vim.uri_encode(v)
	end
	local s_encoded_body = table.concat(t_encoded_body, "&")

	M.b64_client = vim.base64.encode(M.client_id .. ":" .. M.client_secret)
	local headers = {
		["Content-Type"] = "application/x-www-form-urlencoded",
		["Authorization"] = "Basic " .. M.b64_client,
	}

	local response, err = curl.request({
		url = url,
		method = "POST",
		body = s_encoded_body,
		headers = headers,
	})

	if err then
		vim.notify("Error: " .. err, vim.log.levels.ERROR, { title = title })
	end

	if response.status == 200 then
		local data = vim.json.decode(response.body)
		M.access_token = data.access_token
		-- Update
		utils_file.save_credentials({
			access_token = M.access_token,
			refresh_token = M.refresh_token,
			b64_client = M.b64_client,
		}, true)
		vim.notify("Access token refreshed successfully!", vim.log.levels.INFO, { title = title })
	else
		vim.notify("Failed to refresh token: " .. response.body, vim.log.levels.ERROR, { title = title })
	end
end

M.get_current_song = function()
	if not M.access_token then
		vim.notify("Access token is missing. Please authorize first.", vim.log.levels.ERROR, { title = title })
		return
	end
end

return M
