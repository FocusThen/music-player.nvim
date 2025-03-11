local sha256 = require("utils.sha2").sha256

local M = {}

M.build_authorization_url = function(client_id, redirect_uri)
	local code_challenge, code_verifier = M.generate_code_challenge()

	local base_url = "https://accounts.spotify.com/authorize"
	local params = {
		client_id = client_id,
		redirect_uri = redirect_uri,
		response_type = "code",
		scope = "user-read-currently-playing user-modify-playback-state",
		code_challenge_method = "S256",
		code_challenge = code_challenge,
	}
	local encoded_params = {}
	for k, v in pairs(params) do
		encoded_params[#encoded_params + 1] = k .. "=" .. vim.uri_encode(v)
	end

	return base_url .. "?" .. table.concat(encoded_params, "&"), code_challenge, code_verifier
end

M.open_browser = function(url)
	local cmd
	if vim.fn.has("mac") == 1 then
		cmd = string.format("open '%s'", url)
	elseif vim.fn.has("unix") == 1 then
		cmd = string.format("xdg-open '%s'", url)
	elseif vim.fn.has("win32") == 1 then
		cmd = string.format("start '%s'", url)
	end
	vim.fn.jobstart(cmd, { detach = true })
end

local function hex_to_binary(hex)
	return (hex:gsub("..", function(cc)
		return string.char(tonumber(cc, 16))
	end))
end

local function generate_code_verifier(length)
	length = length or 64
	assert(length >= 43 and length <= 128, "Verifier length must be between 43 and 128")

	local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
	local verifier = {}

	math.randomseed(os.time() + vim.uv.hrtime()) -- better random seed

	for _ = 1, length do
		local rand = math.random(#charset)
		table.insert(verifier, charset:sub(rand, rand))
	end

	return table.concat(verifier)
end

local function base64url(input)
	local b64 = vim.base64.encode(input)
	b64 = b64:gsub("\n", "")
	return b64:gsub("+", "-"):gsub("/", "_"):gsub("=", "")
end

M.generate_code_challenge = function()
	local verifier = generate_code_verifier()
	local hex_digest = sha256(verifier)
	return base64url(hex_to_binary(hex_digest)), verifier
end

return M
