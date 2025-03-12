local uv = vim.uv

local M = {}

-- refactor this for redirect_url
M.start_server = function(callback)
	local server = uv.new_tcp()
	if not server then
		return
	end
	assert(server:bind("127.0.0.1", 3001))

	server:listen(128, function(err)
		assert(not err, err)

		local client = uv.new_tcp()
		if not client then
			return
		end
		server:accept(client)
		client:read_start(function(reason, data)
			assert(not reason, reason)
			if data then
				local path, _ = data:match("GET%s+([^%s]+)%s+HTTP")

				if path then
					local code = path:match("callback%?code=([^&]+)")

					local response = [[
              HTTP/1.1 200 OK
              Content-Type: text/html

              <html><body><h1>You can close this window</h1></body></html>]]
					client:write(response)

					-- Close the connection
					client:shutdown(function()
						client:close()
					end)

					server:close()

					if callback then
						callback(code)
					end
				else
					local response = [[
              HTTP/1.1 404 Not Found
              Content-Type: text/html

              <html><body><h1>404 Not Found</h1></body></html>]]
					client:write(response)
					client:shutdown(function()
						client:close()
					end)
				end
			end
		end)
	end)

	print("Server running at http://127.0.0.1:3001/ ... Waiting for Spotify redirect...")
end

return M
