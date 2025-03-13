vim.api.nvim_create_user_command("MPlayer", function()
	require("music-player").authorize()
end, {})

vim.api.nvim_create_user_command("MPlayerCurrentSong", function()
	require("music-player").get_current_song(true)
end, {})

vim.api.nvim_create_user_command("MPlayerStart", function()
	require("music-player").start_polling()
end, {})

vim.api.nvim_create_user_command("MPlayerStop", function()
	require("music-player").stop_polling()
end, {})

vim.api.nvim_create_user_command("MPlayerPlay", function()
	require("music-player").play_track()
end, {})
vim.api.nvim_create_user_command("MPlayerPause", function()
	require("music-player").pause_track()
end, {})

vim.api.nvim_create_user_command("MPlayerNext", function()
	require("music-player").next_track()
end, {})
vim.api.nvim_create_user_command("MPlayerPrev", function()
	require("music-player").previous_track()
end, {})

vim.api.nvim_create_user_command("MPlayerClean", function()
	require("music-player").stop_polling()
	require("music-player").remove_saved_file()
end, {})

vim.api.nvim_create_user_command("MPlayerR", function()
	require("music-player").fn_refresh_token()
end, {})

