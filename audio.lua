local audio = {}

local function loadAudio(path, type)
	local success, source = pcall(love.audio.newSource, path, type)
	if not success then
		print("Error loading audio: " .. path .. " - " .. tostring(source))
		return nil
	end
	return source
end

audio.music_tracks = {
	level1 = loadAudio("assets/music_level1.mp3", "stream"),
	level2 = loadAudio("assets/music_level2.mp3", "stream")
}

audio.background_music = nil
audio.sound = {}
audio.sound.slash_sound = loadAudio("assets/slash.wav", "static")
audio.sound.powerup_sound = loadAudio("assets/powerup.wav", "static")
audio.sound.bomb_sound = loadAudio("assets/bomb.wav", "static")
audio.sound.levelup_sound = loadAudio("assets/levelup.wav", "static")
audio.sound.life_sound = loadAudio("assets/life.wav", "static")
audio.sound.click_sound = loadAudio("assets/click.wav", "static")

audio.sound.special_sound = loadAudio("assets/special.wav", "static")

return audio