# Music player (Spotify) for neovim

* authorize
    * [Spotify Developers](https://developer.spotify.com/)
    * Go there and create an App and Get your `Cliend ID` and `Client secret`
    * `require("music-player").authorize()` creating setup basically does the same, ask about information that above
    * Lastly `Code` right now i am working on it how to get it but it basically in url after redirect `?code=xxxx`.
    * All information above saved in your `.config/nvim/music-player-credentials.json`
    * `Cliend ID` and `Client secret` saved as `b64_client` which means not in raw.

* `:MPlayer` & `require("music-player").authorize()`
* `:MPlayerCurrentSong` & `require("music-player").get_current_song()`
    * Notify about song state and artist - song name
* `:MPlayerStart` & `require("music-player").start_polling()`
    * Creates timer and checks `:MPlayerCurrentSong` every 5 secs
* `:MPlayerStop` & `require("music-player").stop_polling()`
    * Stops timer

# TODOS
### Building Steps
- [x] Create repo
- [x] Create basic folder structure
- [ ] Naming is hard what should I name it
---
### Login stuff

- [x] login spotify is pain in the ass
- [x] redirect user to get code or something
- [x] get Code somehow and connect the spotify
- [x] save the data what we have given
- [ ] create server that lisen on that redirect url and get the code(be smart).
- [x] Get information `https://api.spotify.com/v1/me/player/currently-playing`
- [x] Print console basic information such as what is playing
- [x] Instead using console, toast it information with `vim.notify`

---
### Functions

- [ ] create reset fn
- [ ] create fn that shows currently playing
- [ ] create fn maybe goes next or prev?
- [ ] create fn maybe pause?
- [x] create track last song every 5 sec if changed notify!

---
### Finishing
- [ ] Bind fn's together so anyone can use
- [ ] After learn LUA refactor this garbage

