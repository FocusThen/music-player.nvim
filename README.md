# Music player for neovim

### Building Steps
- [x] Create repo
- [x] Create basic folder structure
- [ ] Naming is hard what should i name it
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
