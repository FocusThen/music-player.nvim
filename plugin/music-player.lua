vim.api.nvim_create_user_command("MPlayer", function()
	require("music-player").authorize()
end, {})

vim.api.nvim_create_user_command("MPlayerCurrentSong", function()
	require("music-player").get_current_song()
end, {})

vim.api.nvim_create_user_command("MPlayerStart", function()
	require("music-player").start_polling()
end, {})
vim.api.nvim_create_user_command("MPlayerStop", function()
	require("music-player").stop_polling()
end, {})
