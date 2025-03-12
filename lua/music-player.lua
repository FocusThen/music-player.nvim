local curl = require("plenary.curl")
local utils = require("utils.utils")
local utils_file = require("utils.file")
local utils_timer = require("utils.timer")
local server = require("utils.server")

local title = "Music Player (Spotify)"
local last_track_id = nil
local last_is_playing = nil
local client_id = "02361f61d8864da1b3d6a85c3fa725d7" -- mine
local redirect_url = "http://localhost:3001/callback"
local should_start_polling = false

local M = {
	b64_client = nil,
	auth_code = nil,
	refresh_token = nil,
	access_token = nil,
	code_challenge = nil,
	code_verifier = nil,
}

M.setup = function()
	M.authorize()
	if should_start_polling then
	   M.start_polling()
	end
end

M.authorize = function()
	local credentials = utils_file.read_credentials()

	if credentials then
		M.access_token = credentials.access_token
		M.refresh_token = credentials.refresh_token
		should_start_polling = true
		return
	end

	local auth_url, code_challenge, code_verifier = utils.build_authorization_url(client_id, redirect_url)
	M.code_challenge = code_challenge
	M.code_verifier = code_verifier
	server.start_server(function(code)
		if code then
			M.auth_code = code
			vim.schedule(function()
				M.get_tokens()
			end)
		else
			vim.notify("Authorization code is missing.", vim.log.levels.ERROR, { title = title })
		end
	end)
	print("Opening browser for Spotify authorization...")
	utils.open_browser(auth_url)
end

M.get_tokens = function()
	if not M.auth_code then
		vim.notify("Authorization code is missing.", vim.log.levels.ERROR, { title = title })
		return
	end

	local url = "https://accounts.spotify.com/api/token"
	local body = {
		client_id = client_id,
		grant_type = "authorization_code",
		code = M.auth_code,
		redirect_uri = redirect_url,
		code_verifier = M.code_verifier,
	}
	local t_encoded_body = {}
	for k, v in pairs(body) do
		t_encoded_body[#t_encoded_body + 1] = k .. "=" .. vim.uri_encode(v)
	end
	local s_encoded_body = table.concat(t_encoded_body, "&")

	local headers = {
		["Content-Type"] = "application/x-www-form-urlencoded",
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

		--	Save
		utils_file.save_credentials({
			access_token = M.access_token,
			refresh_token = M.refresh_token,
		})

		should_start_polling = true
	else
		vim.notify("Failed to retrieve tokens - token api: " .. response.body, vim.log.levels.ERROR, { title = title })
	end
end

M.fn_refresh_token = function()
	if not M.refresh_token then
		vim.notify("Refresh token is missing.", vim.log.levels.ERROR, { title = title })
		return
	end

	local url = "https://accounts.spotify.com/api/token"
	local body = {
		client_id = client_id,
		grant_type = "refresh_token",
		refresh_token = M.refresh_token,
		redirect_uri = redirect_url,
		code_verifier = utils.code_verifier,
	}

	local t_encoded_body = {}
	for k, v in pairs(body) do
		t_encoded_body[#t_encoded_body + 1] = k .. "=" .. vim.uri_encode(v)
	end
	local s_encoded_body = table.concat(t_encoded_body, "&")

	local headers = {
		["Content-Type"] = "application/x-www-form-urlencoded",
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
		}, true)
		vim.notify("Access token refreshed successfully!", vim.log.levels.INFO, { title = title })
	else
		vim.notify("Failed to refresh token: " .. response.body, vim.log.levels.ERROR, { title = title })
	end
end

M.get_current_song = function(should_notify)
	if not M.access_token then
		vim.notify("Access token is missing. Please authorize first.", vim.log.levels.ERROR, { title = title })
		return
	end

	local url = "https://api.spotify.com/v1/me/player/currently-playing"
	local headers = {
		["Authorization"] = "Bearer " .. M.access_token,
	}

	local response, err = curl.request({
		url = url,
		method = "GET",
		headers = headers,
	})

	if err then
		vim.notify("Error: " .. err, vim.log.levels.ERROR, { title = title })
	end

	if response.status == 200 then
		local data = vim.json.decode(response.body)
		if data and data.item then
			local artist_name = data.item.artists[1].name
			local track_name = data.item.name
			local track_id = data.item.id
			local is_playing = data.is_playing

			if should_notify then
				vim.notify(
					string.format("Now playing: %s - %s", artist_name, track_name),
					vim.log.levels.INFO,
					{ title = title }
				)
			end

			if last_track_id ~= track_id then
				if last_track_id == nil then
					vim.notify(
						string.format("Now playing: %s - %s", artist_name, track_name),
						vim.log.levels.INFO,
						{ title = title }
					)
				else
					vim.notify(
						string.format("Next song: %s - %s", artist_name, track_name),
						vim.log.levels.INFO,
						{ title = title }
					)
				end
				last_track_id = track_id
				last_is_playing = is_playing
			--
			-- resume check
			--
			elseif last_is_playing ~= is_playing then
				if is_playing then
					vim.notify("Playback resumed", vim.log.levels.INFO, { title = title })
				else
					vim.notify("Playback paused", vim.log.levels.WARN, { title = title })
				end
				last_is_playing = is_playing
			end
		else
			--
			-- Finish check
			--
			if last_track_id ~= nil then
				vim.notify("Song finished", vim.log.levels.WARN, { title = title })
				last_track_id = nil
				last_is_playing = nil
			end
		end
	elseif response.status == 204 then
		--
		-- Finish check
		--
		if last_track_id ~= nil then
			vim.notify("Song finished", vim.log.levels.WARN, { title = title })
			last_track_id = nil
			last_is_playing = nil
		end
	elseif response.status == 401 then
		vim.notify("Access token expired. Refreshing token...", vim.log.levels.WARN, { title = title })
		M.fn_refresh_token()
	else
		vim.notify("Error: " .. response.body, vim.log.levels.ERROR, { title = title })
		utils_timer.stop_polling()
	end
end

M.player_state_control = function(state, mod)
	if not M.access_token then
		vim.notify("Access token is missing. Please authorize first.", vim.log.levels.ERROR, { title = title })
		return
	end

	local url = "https://api.spotify.com/v1/me/player/" .. state
	local headers = {
		["Authorization"] = "Bearer " .. M.access_token,
	}

	local response, err = curl.request({
		url = url,
		method = mod,
		headers = headers,
	})

	if err then
		vim.notify("Error: " .. err, vim.log.levels.ERROR, { title = title })
	end

	if response.status == 200 then
		return
	end
	if response.status == 204 then
		vim.notify("State: " .. state, vim.log.levels.INFO, { title = title })
	elseif response.status == 401 then
		vim.notify("Access token expired. Refreshing token...", vim.log.levels.WARN, { title = title })
		M.fn_refresh_token()
	else
		vim.notify("Error: " .. response.body, vim.log.levels.ERROR, { title = title })
	end
end

M.next_track = function()
	M.player_state_control("next", "POST")
end
M.previous_track = function()
	M.player_state_control("previous", "POST")
end
M.pause_track = function()
	M.player_state_control("pause", "PUT")
end
M.play_track = function()
	M.player_state_control("play", "PUT")
end
--
--
-- remap
M.start_polling = function()
	utils_timer.start_polling(function()
		M.get_current_song()
	end)
end
M.stop_polling = function()
	utils_timer.stop_polling()
end
--- remove saved file
M.remove_saved_file = function()
	utils_file.reset_file()
end
return M
