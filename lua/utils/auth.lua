local curl = require("plenary.curl")
local notify = require("notify")

local AUTH_API_TOKEN = "https://accounts.spotify.com/api/token"
local CREDENTIALS_FILE = vim.fn.stdpath("config") .. "/spotify_credentials.json"

local M = {}

local function get_and_save_credentials()
	local client_id = vim.fn.input("Enter your Spotify Client ID: ")
	local client_secret = vim.fn.inputsecret("Enter your Spotify Client Secret: ")

	local encoded_client = vim.fn.system(string.format("echo -n '%s:%s' | base64", client_id, client_secret))
	encoded_client = vim.fn.trim(encoded_client)

	local credentials = {
		encoded_client = encoded_client,
	}

	local json_data = vim.fn.json_encode(credentials)

	local file = io.open(CREDENTIALS_FILE, "w")
	if file == nil then
		print("error while openning file")
		return
	end

	file:write(json_data)
	file:close()

	print("Credentials saved to " .. CREDENTIALS_FILE)
end

local function read_credentials()
	local file = io.open(CREDENTIALS_FILE, "r")
	if file then
		local content = file:read("*a")
		file:close()

		local credentials = vim.fn.json_decode(content)
		return credentials.encoded_client
	else
		print("No saved credentials found.")
		return nil
	end
end

M.get_credentials = function(reset)
	local encoded_client = read_credentials()

	if not encoded_client or reset then
		get_and_save_credentials()

		-- Try reading them again after saving
		encoded_client = read_credentials()
	end

	return encoded_client
end

M.login_with_credentials = function(encoded_client)
	local headers = {
		["Authorization"] = "Bearer " .. encoded_client,
	}
	local post_data = "grant_type=client_credentials"
	local response, err = curl.post(AUTH_API_TOKEN, {
		headers = headers,
		body = post_data,
	})

	local logined_user

	if err then
		notify("musicPlayer Auth Error: " .. err, vim.log.levels.ERROR)
		return nil
	else
		local body = response.body
		local json = vim.fn.json_decode(body)
		if json.error then
			notify(json.error, vim.log.levels.ERROR)
			return nil
		else
			logined_user = json
		end
	end

	return logined_user
end

return M
