vim.api.nvim_create_user_command("MPlayer", function()
	require("music-player").authorize()
end, {})
-- vim.api.nvim_create_user_command("SpotifyCurrentSong", player.get_current_song, {})
