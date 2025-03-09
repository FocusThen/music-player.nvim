local curl = require("plenary.curl")
local utils = require("utils.utils")
local utils_file = require("utils.file")
local uv = vim.loop

local title = "Music Player (Spotify)"
local polling_interval = 5 -- seconds
local timer = nil
local last_track_id = nil
local last_is_playing = nil

local M = {
	client_id = nil,
	client_secret = nil,
	b64_client = nil,
	auth_code = nil,
	refresh_token = nil,
	access_token = nil,
	redirect_url = "http://localhost",
}

M.setup = function(config)
	if not config or not config.redirect_url then
		vim.notify("music-player redirect_url is required.", vim.log.levels.ERROR, { title = title })
		return
	end

	M.redirect_url = config.redirect_url
	M.authorize()
	M.start_polling()
end

M.authorize = function(cb)
	local credentials = utils_file.read_credentials()

	if credentials then
		M.access_token = credentials.access_token
		M.refresh_token = credentials.refresh_token
		M.b64_client = credentials.b64_client
		if cb then
			vim.notify("Saved Tokens retrieved successfully!", vim.log.levels.INFO, { title = title })
			cb()
		end
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
		-- Callback if needded
		if cb then
			cb()
		end
	end)
end

M.get_tokens = function()
	if not M.auth_code then
		vim.notify("Authorization code is missing.", vim.log.levels.ERROR, { title = title })
		M.authorize(M.get_tokens)
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

M.get_current_song = function(should_notify)
	if not M.access_token then
		vim.notify("Access token is missing. Please authorize first.", vim.log.levels.ERROR, { title = title })
		M.authorize(M.get_current_song)
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
		M.stop_polling()
	end
end

M.start_polling = function()
	if timer then
		M.stop_polling()
	end
	timer = uv.new_timer()
	if timer ~= nil then
		timer:start(
			polling_interval * 1000,
			polling_interval * 1000,
			vim.schedule_wrap(function()
				M.get_current_song()
			end)
		)
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
