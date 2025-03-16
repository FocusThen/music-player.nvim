# Music player (Spotify) for neovim

* authorize
    * For `Code` code opens default browser but behind the scene i make lua server so i can get the code.
    * `access_token` and `refresh_token` saved in `.config/nvim/music-player-credentials.json`

* `:MPlayer` & `require("music-player").authorize()`
* `:MPlayerCurrentSong` & `require("music-player").get_current_song()`
    * Notify about song state and artist - song name
* `:MPlayerStart` & `require("music-player").start_polling()`
    * Creates timer and checks `:MPlayerCurrentSong` every 5 secs
* `:MPlayerStop` & `require("music-player").stop_polling()`
    * Stops timer


### Player
* `:MPlayerPlay`
* `:MPlayerPause`
* `:MPlayerNext`
* `:MPlayerPrev`

### FILE
* `:MPlayerClean`
    * removes saved file.

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
- [x] create server that lisen on that redirect url and get the code(be smart).
- [x] Get information `https://api.spotify.com/v1/me/player/currently-playing`
- [x] Print console basic information such as what is playing
- [x] Instead using console, toast it information with `vim.notify`
- [x] PKCE ????????? you don't need something like client secret ?

---
### Functions

- [x] create fn that shows currently playing
- [x] create fn maybe goes next or prev?
- [x] create fn maybe pause?
- [x] create track last song every 5 sec if changed notify!
- [x] right now we are checking every 5 sec songs, we might need check if user inactive if user afk we should stop requesting.
---
### Finishing
- [x] Bind fn's together so anyone can use
- [ ] After learn LUA refactor this garbage


### Bugs!
- [x] Some times in `utils.timer` -> `vim.schedule_wrap` fails and gives error about currently playing unfinished or something.


