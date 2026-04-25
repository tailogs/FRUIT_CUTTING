local fruits = {}
local pieces = {}
local particles = {}
local powerups = {}
local bombs = {}
local score = 0
local combo_timer = 0
local missed = 0
local max_missed = 8
local game_state = "menu"
local spawn_timer = 0
local spawn_interval = 1.5
local blade_path = {}
local level = 1
local level_progress = 0
local level_threshold = 50
local shake_timer = 0
local shake_intensity = 0
local background_offset = 0
local crt_flicker = 0
local menu_transition = 0
local life_recovery_timer = 0
local cursor_pulse = 0
local combo_pulse = 0
local special_move_charge = 0
local special_move_cooldown = 0
local player_xp = 0
local player_level = 1
local xp_to_next_level = 100
local time_remaining = 60
local game_font, ui_font_large, ui_font_small
local menu_buttons = {}
local pause_buttons = {}
local options_buttons = {}
local ingame_buttons = {}
local esc_buttons = {}
local music_enabled = true
local sfx_enabled = true
local low_contrast = false
local difficulty = "medium"
local hovered_button = nil
local particle_pool = {}
local max_particles = 500
local silhouette_timer = 0
local silhouettes = {}
local fruit_sprites = {}
local blade_sprites = {default = nil}
local current_blade = "default"

local colors             = require("colors")
local audio              = require("audio")
local objects            = require("objects")
local save_and_open_data = require("save_and_open_data")

function love.load()
    love.window.setFullscreen(true)
    love.graphics.setBackgroundColor(0.1, 0.15, 0.2)
    love.window.setTitle("FRUIT_CUTTING")
    love.mouse.setVisible(false)
    math.randomseed(os.time())
	
    if audio.music_tracks.level1 then
        audio.background_music = audio.music_tracks.level1
        audio.background_music:setVolume(0.5)
        audio.background_music:setLooping(true)
        if music_enabled then audio.background_music:play() end
    else
        print("Warning: Background music not loaded")
    end

    fruit_sprites = {
        Apple = love.graphics.newImage("assets/apple.png"),
        Banana = love.graphics.newImage("assets/banana.png"),
        Blueberry = love.graphics.newImage("assets/blueberry.png"),
        Orange = love.graphics.newImage("assets/orange.png"),
        Grape = love.graphics.newImage("assets/grape.png"),
        ["Golden Fruit"] = love.graphics.newImage("assets/golden_fruit.png")
    }
    blade_sprites.default = love.graphics.newImage("assets/blade_default.png")

    game_font = love.graphics.newFont("assets/pixel_font.ttf", 24)
    ui_font_large = love.graphics.newFont("assets/pixel_font.ttf", 48)
    ui_font_small = love.graphics.newFont("assets/pixel_font.ttf", 20)
    love.graphics.setFont(game_font)

    save_and_open_data.open_file_progress()

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    menu_buttons = {
		{text = "Classic", x = w/2 - 200, y = h/2 - 100, w = 400, h = 70, action = function()
			resetGame()
			game_state = difficulty == "zen" and "zen" or "playing"
			menu_transition = 1
			if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
		end},
		{text = "Time Attack", x = w/2 - 200, y = h/2 - 20, w = 400, h = 70, action = function()
			resetGame()
			game_state = "time_attack"
			time_remaining = 60
			menu_transition = 1
			if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
		end},
		{text = "Survival", x = w/2 - 200, y = h/2 + 60, w = 400, h = 70, action = function()
			resetGame()
			game_state = "survival"
			spawn_interval = 2.0
			menu_transition = 1
			if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
		end},
		{text = "Options", x = w/2 - 200, y = h/2 + 140, w = 400, h = 70, action = function()
			game_state = "options"
			menu_transition = 1
			if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
		end},
		{text = "Exit", x = w/2 - 200, y = h/2 + 220, w = 400, h = 70, action = function()
			love.event.quit()
			if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
		end}
	}
    pause_buttons = {
        {text = "Resume", x = w/2 - 200, y = h/2 - 160, w = 400, h = 70, action = function()
            game_state = difficulty == "zen" and "zen" or (game_state == "time_attack" and "time_attack" or "playing")
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Restart", x = w/2 - 200, y = h/2 - 80, w = 400, h = 70, action = function()
            resetGame()
            game_state = difficulty == "zen" and "zen" or (game_state == "time_attack" and "time_attack" or "playing")
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Return to Menu", x = w/2 - 200, y = h/2, w = 400, h = 70, action = function()
            game_state = "menu"
            menu_transition = 1
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Exit", x = w/2 - 200, y = h/2 + 80, w = 400, h = 70, action = function()
            love.event.quit()
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end}
    }
    options_buttons = {
        {text = function() return "Music: " .. (music_enabled and "On" or "Off") end, x = w/2 - 200, y = h/2 - 320, w = 400, h = 70, action = function()
            music_enabled = not music_enabled
            if music_enabled and audio.background_music then audio.background_music:play() else if audio.background_music then audio.background_music:stop() end end
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = function() return "SFX: " .. (sfx_enabled and "On" or "Off") end, x = w/2 - 200, y = h/2 - 240, w = 400, h = 70, action = function()
            sfx_enabled = not sfx_enabled
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = function() return "Difficulty: " .. difficulty:gsub("^%l", string.upper) end, x = w/2 - 200, y = h/2 - 160, w = 400, h = 70, action = function()
            if difficulty == "easy" then difficulty = "medium"
            elseif difficulty == "medium" then difficulty = "hard"
            elseif difficulty == "hard" then difficulty = "zen"
            else difficulty = "easy" end
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = function() return "Low Contrast: " .. (low_contrast and "On" or "Off") end, x = w/2 - 200, y = h/2 - 80, w = 400, h = 70, action = function()
            low_contrast = not low_contrast
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Achievements", x = w/2 - 200, y = h/2, w = 400, h = 70, action = function()
            game_state = "achievements"
            menu_transition = 1
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Back", x = w/2 - 200, y = h/2 + 80, w = 400, h = 70, action = function()
            game_state = "menu"
            menu_transition = 1
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end}
    }
    ingame_buttons = {
        {text = function() return "Music Volume: " .. string.format("%.0f%%", audio.background_music and audio.background_music:getVolume() * 100 or 0) end, x = w - 250, y = 50, w = 200, h = 50, action = function()
            if audio.background_music then
                local vol = audio.background_music:getVolume()
                audio.background_music:setVolume(vol >= 0.9 and 0 or math.min(1, vol + 0.1))
            end
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Stats", x = w - 250, y = 110, w = 200, h = 50, action = function()
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Pause", x = w - 250, y = 170, w = 200, h = 50, action = function()
            game_state = "paused"
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Return to Menu", x = w - 250, y = 230, w = 200, h = 50, action = function()
            game_state = "menu"
            menu_transition = 1
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end}
    }
    esc_buttons = {
        {text = "Resume", x = w/2 - 200, y = h/2 - 320, w = 400, h = 70, action = function()
            game_state = difficulty == "zen" and "zen" or (game_state == "time_attack" and "time_attack" or "playing")
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Restart", x = w/2 - 200, y = h/2 - 240, w = 400, h = 70, action = function()
            resetGame()
            game_state = difficulty == "zen" and "zen" or (game_state == "time_attack" and "time_attack" or "playing")
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = function() return "Music Volume: " .. string.format("%.0f%%", audio.background_music and audio.background_music:getVolume() * 100 or 0) end, x = w/2 - 200, y = h/2 - 160, w = 400, h = 70, action = function()
            if audio.background_music then
                local vol = audio.background_music:getVolume()
                audio.background_music:setVolume(vol >= 0.9 and 0 or math.min(1, vol + 0.1))
            end
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = function() return "SFX Volume: " .. (sfx_enabled and "On" or "Off") end, x = w/2 - 200, y = h/2 - 80, w = 400, h = 70, action = function()
            sfx_enabled = not sfx_enabled
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Return to Menu", x = w/2 - 200, y = h/2, w = 400, h = 70, action = function()
            game_state = "menu"
            menu_transition = 1
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end},
        {text = "Exit", x = w/2 - 200, y = h/2 + 80, w = 400, h = 70, action = function()
            love.event.quit()
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end}
    }
end

function love.update(dt)
    if type(missed) ~= "number" then missed = 0 end
    if type(max_missed) ~= "number" then max_missed = 8 end
    if type(special_move_charge) ~= "number" then special_move_charge = 0 end

    cursor_pulse = cursor_pulse + dt * 2
    combo_pulse = objects.combo > 3 and (combo_pulse + dt * 5) or 0
    silhouette_timer = silhouette_timer + dt

    if game_state == "menu" or game_state == "paused" or game_state == "options" or game_state == "ingame_menu" or game_state == "esc_menu" or game_state == "achievements" then
        local mx, my = love.mouse.getPosition()
        hovered_button = nil
        local buttons
        if game_state == "menu" then buttons = menu_buttons
        elseif game_state == "paused" then buttons = pause_buttons
        elseif game_state == "options" then buttons = options_buttons
        elseif game_state == "esc_menu" then buttons = esc_buttons
        elseif game_state == "achievements" then buttons = {}
        else buttons = ingame_buttons end
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                hovered_button = btn
                break
            end
        end
        menu_transition = math.max(0, menu_transition - dt * 2)
        return
    end
    if game_state == "game_over" then
        menu_transition = math.max(0, menu_transition - dt * 2)
        return
    end

	local time_scale = 1
	for _, p in ipairs(objects.active_powerups) do
		if p.effect == "slow" then time_scale = 0.6 end
		if p.effect == "frenzy" then time_scale = 1.1 end
	end
	dt = dt * time_scale

    local difficulty_mod = difficulty == "easy" and 1.8 or (difficulty == "hard" and 0.8 or (difficulty == "zen" and 2.0 or 1.2))
    local adjusted_interval = spawn_interval * difficulty_mod
    if game_state == "survival" then
        spawn_interval = math.max(0.3, spawn_interval - dt * 0.01)
    end

    spawn_timer = spawn_timer + dt
    if spawn_timer >= adjusted_interval then
        local rand = math.random()
        local golden_chance = math.max(0.05, 0.15 - level * 0.01)
        local bomb_chance = difficulty == "zen" and 0 or 0.03
        if rand < 0.15 then
            spawnPowerup()
        elseif rand < 0.15 + bomb_chance then
            spawnBomb()
        elseif rand < 0.15 + bomb_chance + golden_chance then
            spawnFruit(true)
        else
            spawnFruit()
        end
        spawn_timer = 0
        spawn_interval = math.max(0.4, spawn_interval - 0.005)
    end

	for i = #fruits, 1, -1 do
		local f = fruits[i]
		f.x = f.x + f.dx * dt
		f.y = f.y + f.dy * dt
		f.dy = f.dy + 100 * dt
		f.dx = f.dx * (1 - 0.1 * dt)
		f.dy = f.dy * (1 - 0.1 * dt)
		f.rotation = f.rotation + f.dr * dt
		if f.y < -f.radius or f.y > love.graphics.getHeight() + f.radius or f.x < -f.radius or f.x > love.graphics.getWidth() + f.radius or f.radius < 20 then
			table.remove(fruits, i)
			if not f.sliced and not f.rare and game_state ~= "zen" and game_state ~= "time_attack" then
				missed = missed + 1
				objects.combo = 0
				if missed >= max_missed then game_state = "game_over" end
			end
		end
	end

	for i = #pieces, 1, -1 do
		local p = pieces[i]
		p.x = p.x + p.dx * dt
		p.y = p.y + p.dy * dt
		p.dy = p.dy + 400 * dt
		p.rotation = p.rotation + p.dr * dt
		p.life = p.life - dt
		if p.life <= 0 then table.remove(pieces, i) end
	end

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            p.active = false
            table.remove(particles, i)
            table.insert(particle_pool, p)
        end
    end

    for i = #powerups, 1, -1 do
        local p = powerups[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.dy = p.dy + 400 * dt
        p.rotation = p.rotation + p.dr * dt
        if p.y < -50 or p.x < -50 or p.x > love.graphics.getWidth() + 50 then
            table.remove(powerups, i)
        end
    end

	for i = #bombs, 1, -1 do
		local b = bombs[i]
		b.x = b.x + b.dx * dt
		b.y = b.y + b.dy * dt
		b.dy = b.dy + 400 * dt
		b.rotation = b.rotation + b.dr * dt
		if b.y < -50 or b.x < -50 or b.x > love.graphics.getWidth() + 50 then
			table.remove(bombs, i)
		end
	end

    for i = #objects.active_powerups, 1, -1 do
        local p = objects.active_powerups[i]
        p.duration = p.duration - dt
        if p.duration <= 0 and p.effect ~= "life" and p.effect ~= "clear" then
            table.remove(objects.active_powerups, i)
        end
    end

    if #blade_path > 0 then
        for i = #blade_path, 1, -1 do
            blade_path[i].life = blade_path[i].life - dt
            if blade_path[i].life <= 0 then table.remove(blade_path, i) end
        end
    end

    if objects.combo > 0 then
        combo_timer = combo_timer - dt
        if combo_timer <= 0 then objects.combo = 0 end
    end

    special_move_cooldown = math.max(0, special_move_cooldown - dt)
    if game_state ~= "zen" then
        special_move_charge = math.min(100, special_move_charge + dt * 10)
    end

    if score >= level_progress + level_threshold then
        level = level + 1
        player_xp = player_xp + 50
        if player_xp >= xp_to_next_level then
            player_level = player_level + 1
            xp_to_next_level = xp_to_next_level * 1.5
            unlockContent(player_level)
        end
        level_progress = score
        level_threshold = level_threshold * 1.15
        spawn_interval = math.max(0.4, spawn_interval * 0.95)
        createParticleExplosion(love.graphics.getWidth()/2, love.graphics.getHeight()/2, {1, 1, 0}, 150, "Level " .. level .. "!")
        if sfx_enabled and audio.sound.levelup_sound then audio.sound.levelup_sound:play() end
        shakeScreen(0.5, 8)
        love.graphics.setBackgroundColor(math.random() * 0.2, math.random() * 0.2, math.random() * 0.3)
        if level <= #audio.music_tracks then
            if music_enabled then
                audio.background_music:stop()
                audio.background_music = music_tracks["level" .. level]
                audio.background_music:play()
            end
        end
    end
	
    if score > (save_and_open_data.get_high_score() or 0) then
        save_and_open_data.set_high_score(score)
    end

    background_offset = background_offset + dt * 50
    if background_offset > love.graphics.getHeight() then
        background_offset = background_offset - love.graphics.getHeight()
    end
    crt_flicker = low_contrast and 0 or (0.03 + math.sin(love.timer.getTime() * 2) * 0.03 * (missed / max_missed))
    if shake_timer > 0 then
        shake_timer = shake_timer - dt
        shake_intensity = shake_intensity * math.max(0, shake_timer / 0.5)
    end
    life_recovery_timer = math.max(0, life_recovery_timer - dt)

    objects:checkAchievements()
	
    autosave_timer = (autosave_timer or 0) + dt
	if autosave_timer > 1 then
        save_and_open_data.save_to_file_progress()
        autosave_timer = 0
    end
end

function love.draw()
    love.graphics.push()
    if shake_timer > 0 then
        love.graphics.translate(
            math.random(-shake_intensity, shake_intensity),
            math.random(-shake_intensity, shake_intensity)
        )
    end

    missed = tonumber(missed) or 0
    max_missed = tonumber(max_missed) or 8
    if max_missed == 0 then max_missed = 8 end
    local life_ratio = game_state == "zen" and 1 or (1 - missed / max_missed)
    local top_color = {0.1 * life_ratio + 0.05, 0.3 * life_ratio + 0.1, 0.5 * life_ratio + 0.15}
    local bottom_color = {0.2 * life_ratio + 0.1, 0.15 * life_ratio + 0.05, 0.3 * life_ratio + 0.1}
    for y = 0, love.graphics.getHeight(), 10 do
        local t = y / love.graphics.getHeight()
        love.graphics.setColor(
            top_color[1] * (1-t) + bottom_color[1] * t,
            top_color[2] * (1-t) + bottom_color[2] * t,
            top_color[3] * (1-t) + bottom_color[3] * t
        )
        love.graphics.rectangle("fill", 0, y, love.graphics.getWidth(), 10)
    end

    if not low_contrast then
        love.graphics.setColor(0, 0, 0, 0.1 + (missed / max_missed) * 0.15)
        for y = 0, love.graphics.getHeight(), 4 do
            love.graphics.line(0, y + background_offset % 4, love.graphics.getWidth(), y + background_offset % 4)
        end
        love.graphics.setColor(0, 0, 0, 0.3 + (missed / max_missed) * 0.2)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 50)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 50, love.graphics.getWidth(), 50)
        love.graphics.rectangle("fill", 0, 0, 50, love.graphics.getHeight())
        love.graphics.rectangle("fill", love.graphics.getWidth() - 50, 0, 50, love.graphics.getHeight())
        for i = 1, 30 * (missed / max_missed + 0.5) do
            love.graphics.setColor(1, 1, 1, math.random(0.05, 0.2))
            love.graphics.rectangle("fill", math.random(0, love.graphics.getWidth()), math.random(0, love.graphics.getHeight()), 2, 2)
        end
    end

    if game_state == "menu" or game_state == "options" or game_state == "achievements" then
        love.graphics.setColor(0, 0, 0, 0.8 * (1 - menu_transition))
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 0)
        love.graphics.setFont(ui_font_large)
        local title = game_state == "menu" and "Fruit Slash: Ultimate" or (game_state == "options" and "Options" or "Achievements")
        local title_width = ui_font_large:getWidth(title)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", (love.graphics.getWidth() - title_width) / 2 - 20, love.graphics.getHeight()/4 - 70, title_width + 40, 80, 10)
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf(title, 0, love.graphics.getHeight()/4 - 65, love.graphics.getWidth(), "center")
        love.graphics.setFont(game_font)
		if game_state == "menu" then
			love.graphics.setColor(1, 1, 1)
			local stats_text = "High Score: " .. tostring(save_and_open_data.get_high_score()) .. " | Coins: " .. tostring(save_and_open_data.get_fruit_coins())
			local stats_width = game_font:getWidth(stats_text)
			love.graphics.setColor(0, 0, 0, 0.6)
			love.graphics.rectangle("fill", (love.graphics.getWidth() - stats_width) / 2 - 10, love.graphics.getHeight()/4 + 32, stats_width + 20, 40, 5)
			love.graphics.setColor(1, 1, 1)
			love.graphics.printf(stats_text, 0, love.graphics.getHeight()/4 + 35, love.graphics.getWidth(), "center")
		elseif game_state == "achievements" then
            love.graphics.setColor(1, 1, 1)
            local y_offset = love.graphics.getHeight()/3
            for i, ach in ipairs(objects.achievements) do
                local ach_text = ach.name .. ": " .. ach.desc .. " (" .. ach.progress .. "/" .. ach.goal .. ")" .. (ach.unlocked and " [Unlocked]" or "")
                local ach_width = game_font:getWidth(ach_text)
                love.graphics.setColor(0, 0, 0, 0.6)
                love.graphics.rectangle("fill", (love.graphics.getWidth() - ach_width) / 2 - 10, y_offset + i*50 - 15, ach_width + 20, 30, 5)
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(ach_text, 0, y_offset + i*50, love.graphics.getWidth(), "center")
            end
        end
        local buttons = game_state == "menu" and menu_buttons or (game_state == "options" and options_buttons or {})
        for i, btn in ipairs(buttons) do
            local scale = btn == hovered_button and 1.15 + math.sin(love.timer.getTime() * 3) * 0.05 or 1
            local alpha = 0.8 + math.sin(love.timer.getTime() * 2 + i) * 0.1
            love.graphics.setColor(btn == hovered_button and {0.6, 0.6, 0.6, alpha} or {0.3, 0.3, 0.3, alpha})
            love.graphics.push()
            love.graphics.translate(btn.x + btn.w/2, btn.y + btn.h/2)
            love.graphics.scale(scale, scale)
            love.graphics.rectangle("fill", -btn.w/2, -btn.h/2, btn.w, btn.h, 15)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.setFont(game_font)
            local text = type(btn.text) == "function" and btn.text() or btn.text
            love.graphics.printf(text, -btn.w/2, -btn.h/2 + 15, btn.w, "center")
            love.graphics.pop()
        end
    elseif game_state == "paused" or game_state == "esc_menu" then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 0)
        love.graphics.setFont(ui_font_large)
        local pause_text = game_state == "paused" and "Paused" or "Menu"
        local pause_width = ui_font_large:getWidth(pause_text)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", (love.graphics.getWidth() - pause_width) / 2 - 20, love.graphics.getHeight()/4 - 150, pause_width + 40, 80, 10)
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf(pause_text, 0, love.graphics.getHeight()/4 - 145, love.graphics.getWidth(), "center")
        local buttons = game_state == "paused" and pause_buttons or esc_buttons
        for i, btn in ipairs(buttons) do
            local scale = btn == hovered_button and 1.15 + math.sin(love.timer.getTime() * 3) * 0.05 or 1
            local alpha = 0.8 + math.sin(love.timer.getTime() * 2 + i) * 0.1
            love.graphics.setColor(btn == hovered_button and {0.6, 0.6, 0.6, alpha} or {0.3, 0.3, 0.3, alpha})
            love.graphics.push()
            love.graphics.translate(btn.x + btn.w/2, btn.y + btn.h/2)
            love.graphics.scale(scale, scale)
            love.graphics.rectangle("fill", -btn.w/2, -btn.h/2, btn.w, btn.h, 15)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.setFont(game_font)
            local text = type(btn.text) == "function" and btn.text() or btn.text
            love.graphics.printf(text, -btn.w/2, -btn.h/2 + 15, btn.w, "center")
            love.graphics.pop()
        end
        love.graphics.setFont(game_font)
    elseif game_state == "playing" or game_state == "zen" or game_state == "time_attack" or game_state == "survival" then
		for _, f in ipairs(fruits) do
			love.graphics.push()
			love.graphics.translate(f.x, f.y)
			love.graphics.rotate(f.rotation)
			local img = fruit_sprites[f.name]
			if f.quad then
				love.graphics.draw(img, f.quad, f.offset_x, f.offset_y, 0, 5 * f.scale, 5 * f.scale, 0, 0)
			else
				love.graphics.draw(img, -f.radius, -f.radius, 0, 5 * f.scale, 5 * f.scale)
			end
			love.graphics.pop()
			if low_contrast then
				love.graphics.setColor(1, 1, 1, 0.5)
				love.graphics.circle("line", f.x, f.y, f.radius + 5, 20)
			end
			if f.rare then
				love.graphics.setColor(1, 1, 1, 0.5 + 0.5 * math.sin(love.timer.getTime() * 5))
				love.graphics.circle("line", f.x, f.y, f.radius + 3, 20)
			end
		end
        for _, p in ipairs(powerups) do
            love.graphics.setColor(p.color)
            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            love.graphics.rotate(p.rotation)
            love.graphics.rectangle("fill", -15, -15, 30, 30, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(ui_font_small)
            love.graphics.printf(p.name, -30, -10, 60, "center")
            love.graphics.setFont(game_font)
            love.graphics.pop()
        end

        for _, b in ipairs(bombs) do
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.push()
            love.graphics.translate(b.x, b.y)
            love.graphics.rotate(b.rotation)
            love.graphics.circle("fill", 0, 0, 20, 20)
            love.graphics.setColor(1, 0, 0)
            love.graphics.setFont(ui_font_small)
            love.graphics.printf("X", -10, -10, 20, "center")
            love.graphics.setFont(game_font)
            love.graphics.pop()
        end

        for _, p in ipairs(particles) do
            if not p.text then
                love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life)
                if p.shape == "star" then
                    local r = p.radius * p.life
                    love.graphics.polygon("fill", p.x, p.y - r, p.x + r * 0.3, p.y - r * 0.3, p.x + r, p.y, p.x + r * 0.3, p.y + r * 0.3, p.x, p.y + r, p.x - r * 0.3, p.y + r * 0.3, p.x - r, p.y, p.x - r * 0.3, p.y - r * 0.3)
                else
                    love.graphics.circle("fill", p.x, p.y, p.radius * p.life)
                end
            end
        end

        if #blade_path >= 2 then
            for i = 1, #blade_path-1 do
                local alpha = math.min(1, blade_path[i].life * 4)
                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.setLineWidth(4 + objects.combo * 0.5)
                love.graphics.line(blade_path[i].x, blade_path[i].y, blade_path[i+1].x, blade_path[i+1].y)
            end
        end

        love.graphics.setFont(game_font)
        local hud_y = 10
        local hud_texts = {
            "Score: "      .. score,
            "High Score: " .. tostring(save_and_open_data.get_high_score()),
            "Coins: "      .. tostring(save_and_open_data.get_fruit_coins()),
            game_state == "time_attack" and "Time: " .. string.format("%.1f", time_remaining) or nil
        }
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 5, 5, 300, 150 + (game_state == "time_attack" and 30 or 0), 10)
        love.graphics.setColor(1, 1, 1)
        for i, text in ipairs(hud_texts) do
            if text then
                love.graphics.print(text, 10, hud_y)
                hud_y = hud_y + 30
            end
        end
        if game_state ~= "zen" then
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 5, hud_y, 300, 40, 5)
            love.graphics.setColor(1, 1, 1)
            for i = 1, max_missed do
                love.graphics.setColor(i > missed and {1, 0, 0} or {0.3, 0.3, 0.3})
                love.graphics.rectangle("fill", 10 + (i-1)*35, hud_y + 5, 30, 30, 5)
            end
            hud_y = hud_y + 60
        end
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 5, hud_y, 300, 45, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Level: " .. level, 10, hud_y + 5)
        hud_y = hud_y + 50
        if game_state ~= "zen" then
            special_move_charge = tonumber(special_move_charge) or 0
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 5, hud_y, 300, 60, 5)
            love.graphics.setColor(1, 0.5, 0.5, 0.8)
            love.graphics.rectangle("fill", 10, hud_y + 30, special_move_charge * 2, 25)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(ui_font_small)
            love.graphics.print("Special Move", 10, hud_y + 5)
            love.graphics.setFont(game_font)
            hud_y = hud_y + 70
        end
        for i, p in ipairs(objects.active_powerups) do
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 5, hud_y, 300, 40, 5)
            love.graphics.setColor(p.color)
            love.graphics.setFont(ui_font_small)
            love.graphics.print(p.name .. ": " .. string.format("%.1f", p.duration), 10, hud_y + 5)
            love.graphics.setFont(game_font)
            hud_y = hud_y + 50
        end

        if objects.combo > 1 then
            local combo_text = "Combo: x" .. objects.combo
            local combo_width = ui_font_large:getWidth(combo_text)
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.rectangle("fill", (love.graphics.getWidth() - combo_width) / 2 - 20, 120 - 30, combo_width + 40, 60, 10)
            love.graphics.setColor(1, 1, 0, 0.8 + math.sin(combo_pulse) * 0.2)
            love.graphics.setFont(ui_font_large)
            love.graphics.printf(combo_text, 0, 85, love.graphics.getWidth(), "center")
            love.graphics.setFont(game_font)
        end

        for _, p in ipairs(particles) do
            if p.text then
                local text_width = ui_font_small:getWidth(p.text)
                love.graphics.setColor(0, 0, 0, 0.6 * p.life)
                love.graphics.rectangle("fill", p.x - text_width/2 - 10, p.y - 15, text_width + 20, 30, 5)
                love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life)
                love.graphics.setFont(ui_font_small)
                love.graphics.printf(p.text, p.x - 50, p.y - 10, 100, "center")
                love.graphics.setFont(game_font)
            end
        end

        if game_state == "ingame_menu" then
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", love.graphics.getWidth() - 300, 0, 300, love.graphics.getHeight())
            for i, btn in ipairs(ingame_buttons) do
                local scale = btn == hovered_button and 1.1 + math.sin(love.timer.getTime() * 3) * 0.05 or 1
                love.graphics.setColor(btn == hovered_button and {0.6, 0.6, 0.6, 0.9} or {0.3, 0.3, 0.3, 0.8})
                love.graphics.push()
                love.graphics.translate(btn.x + btn.w/2, btn.y + btn.h/2)
                love.graphics.scale(scale, scale)
                love.graphics.rectangle("fill", -btn.w/2, -btn.h/2, btn.w, btn.h, 10)
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(game_font)
                local text = type(btn.text) == "function" and btn.text() or btn.text
                love.graphics.printf(text, -btn.w/2, -btn.h/2 + 10, btn.w, "center")
                love.graphics.pop()
            end
            if ingame_buttons[2] == hovered_button then
                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.rectangle("fill", love.graphics.getWidth() - 600, 50, 300, 200, 10)
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(game_font)
                local stats_texts = {
                    "Fruits Sliced: " .. objects.fruits_sliced,
                    "Max objects.combo: " .. objects.combo,
                    "Level: " .. level,
                    "Score: " .. score
                }
                local stats_y = 60
                for _, text in ipairs(stats_texts) do
                    local text_width = game_font:getWidth(text)
                    love.graphics.setColor(0, 0, 0, 0.6)
                    love.graphics.rectangle("fill", love.graphics.getWidth() - 600 + 150 - text_width/2 - 10, stats_y - 10, text_width + 20, 30, 5)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf(text, love.graphics.getWidth() - 600, stats_y, 300, "center")
                    stats_y = stats_y + 40
                end
                love.graphics.setFont(game_font)
            end
        end
    end

    if game_state == "game_over" then
        love.graphics.setColor(0, 0, 0, 0.8 * (1 - menu_transition))
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 0)
        love.graphics.setFont(ui_font_large)
        local go_text = "GAME OVER"
        local go_width = ui_font_large:getWidth(go_text)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", (love.graphics.getWidth() - go_width) / 2 - 20, love.graphics.getHeight()/2 - 110, go_width + 40, -50, 10)
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf(go_text, 0, love.graphics.getHeight()/2 - 170, love.graphics.getWidth(), "center")
        love.graphics.setFont(game_font)
        local go_texts = {
            "Score: " .. score,
            "High Score: " .. save_and_open_data.get_high_score(),
            "Level: " .. level,
            "Coins: " .. save_and_open_data.get_fruit_coins(),
            "Click to Return to Menu"
        }
        local go_y = love.graphics.getHeight()/2 - 30
        for _, text in ipairs(go_texts) do
            local text_width = game_font:getWidth(text)
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.rectangle("fill", (love.graphics.getWidth() - text_width) / 2 - 10, go_y - 15, text_width + 20, 30, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(text, 0, go_y, love.graphics.getWidth(), "center")
            go_y = go_y + 40
        end
        love.graphics.setColor(1, 1, 1, 0.5)
        for i = 1, 100 do
            love.graphics.rectangle("fill", math.random(0, love.graphics.getWidth()), math.random(0, love.graphics.getHeight()), 2, 2)
        end
    end

    if not low_contrast then
        love.graphics.setColor(1, 1, 1, crt_flicker)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(1, 1, 1, 0.8 + math.sin(cursor_pulse) * 0.2)
    love.graphics.draw(blade_sprites[current_blade], mx, my, 0, 1, 1, blade_sprites[current_blade]:getWidth()/2, blade_sprites[current_blade]:getHeight()/2)

    love.graphics.pop()
end

function love.mousemoved(x, y, dx, dy)
    if game_state == "playing" or game_state == "zen" or game_state == "time_attack" or game_state == "survival" then
        table.insert(blade_path, {x = x, y = y, life = 0.2})
        if #blade_path >= 2 then
            checkSlice(blade_path[#blade_path-1], blade_path[#blade_path])
        end
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    if game_state == "menu" then
        for _, btn in ipairs(menu_buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                btn.action()
                break
            end
        end
    elseif game_state == "paused" then
        for _, btn in ipairs(pause_buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                btn.action()
                break
            end
        end
    elseif game_state == "options" then
        for _, btn in ipairs(options_buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                btn.action()
                break
            end
        end
    elseif game_state == "ingame_menu" then
        for _, btn in ipairs(ingame_buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                btn.action()
                break
            end
        end
    elseif game_state == "esc_menu" then
        for _, btn in ipairs(esc_buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                btn.action()
                break
            end
        end
    elseif game_state == "game_over" then
        game_state = "menu"
        menu_transition = 1
    end
end

function love.keypressed(key)
    if key == "p" and (game_state == "playing" or game_state == "zen" or game_state == "time_attack" or game_state == "survival") then
        game_state = "paused"
    elseif key == "p" and game_state == "paused" then
        game_state = difficulty == "zen" and "zen" or (game_state == "time_attack" and "time_attack" or "playing")
    elseif key == "tab" and (game_state == "playing" or game_state == "zen" or game_state == "time_attack" or game_state == "survival") then
        game_state = "ingame_menu"
    elseif key == "tab" and game_state == "ingame_menu" then
        game_state = difficulty == "zen" and "zen" or (game_state == "time_attack" and "time_attack" or "playing")
    elseif key == "escape" then
        if game_state == "menu" then
            love.event.quit()
        elseif game_state == "options" or game_state == "achievements" then
            game_state = "menu"
            menu_transition = 1
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        elseif game_state == "esc_menu" then
            game_state = difficulty == "zen" and "zen" or (game_state == "time_attack" and "time_attack" or "playing")
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        else
            game_state = "esc_menu"
            if sfx_enabled and audio.sound.click_sound then audio.sound.click_sound:play() end
        end
    elseif key == "space" and (game_state == "playing" or game_state == "zen" or game_state == "time_attack" or game_state == "survival") and special_move_cooldown <= 0 and special_move_charge >= 100 then
        special_move_charge = 0
        special_move_cooldown = 10
        for i = #fruits, 1, -1 do
            local f = fruits[i]
            sliceFruit(f, math.random() * math.pi * 2)
            score = score + math.floor(f.points * (1 + objects.combo * 0.2))
            save_and_open_data.set_fruit_coins(save_and_open_data.get_fruit_coins() + f.points)
            objects.fruits_sliced = objects.fruits_sliced + 1
            table.remove(fruits, i)
        end
        for i = #powerups, 1, -1 do
            local p = powerups[i]
            if p.effect == "life" then
                missed = math.max(0, missed - 1)
            else
                table.insert(objects.active_powerups, {effect = p.effect, duration = p.duration, color = p.color, name = p.name})
            end
            createParticleExplosion(p.x, p.y, p.color, 30)
            table.remove(powerups, i)
        end
        for i = #bombs, 1, -1 do
            local b = bombs[i]
            createParticleExplosion(b.x, b.y, {1, 0, 0}, 40)
            table.remove(bombs, i)
        end
        createParticleExplosion(love.graphics.getWidth()/2, love.graphics.getHeight()/2, {1, 0.5, 0.5}, 100, "Special Move!")
        if sfx_enabled and audio.sound.special_sound then audio.sound.special_sound:play() end
        shakeScreen(0.7, 10)
    end
end

function resetGame()
    fruits = {}
    particles = {}
    powerups = {}
    bombs = {}
    objects.active_powerups = {}
    silhouettes = {}
    score = 0
    missed = 0
    objects.combo = 0
    objects.fruits_sliced = 0
    level = 1
    level_progress = 0
    level_threshold = 50
    spawn_interval = 1.5
    spawn_timer = 0
    blade_path = {}
    shake_timer = 0
    life_recovery_timer = 0
    special_move_charge = 0
    special_move_cooldown = 0
    time_remaining = 60
end

function spawnFruit(is_golden)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local fruit_type = is_golden and objects.fruit_types[6] or objects.fruit_types[math.random(1, 5)]
    local radius = fruit_type.radius
    local offset = radius * 0.5
    local scale_factor = math.min(w / 1920, h / 1080)
    local difficulty_mod = difficulty == "easy" and 0.7 or (difficulty == "hard" and 1.3 or (difficulty == "zen" and 0.5 or 1.0))

    local x = -offset
    local y = h + offset

    local target_x, target_y = w, 0
    local angle = math.atan2(target_y - y, target_x - x) + math.random(-0.2, 0.2)
    local speed = math.random(100, 150) * scale_factor * difficulty_mod
    local dx = math.cos(angle) * speed
    local dy = math.sin(angle) * speed

    local fruit = {
        x = x, y = y,
        dx = dx, dy = dy,
        dr = math.random(-5, 5),
        rotation = 0,
        radius = fruit_type.radius,
        color = colors.palette[fruit_type.color],
        points = fruit_type.points,
        rare = fruit_type.rare or false,
        name = fruit_type.name,
        slice_count = 0,
        scale = 1,
        sliced = false
    }
    table.insert(fruits, fruit)
    if fruit.rare then
        createParticleExplosion(fruit.x, fruit.y, {1, 1, 1}, 5, nil, "star")
    end
end

function spawnFruit(is_golden)
    local side = math.random(1, 4)
    local x, y, dx, dy
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local fruit_type = is_golden and objects.fruit_types[6] or objects.fruit_types[math.random(1, 5)]
    local radius = fruit_type.radius
    local offset = radius * 0.5
    local scale_factor = math.min(w / 1920, h / 1080)

    if side == 1 then -- Left
        x = -offset
        y = math.random(radius + 50, h - radius - 50)
        dx = math.random(200, 400) * scale_factor
        dy = -math.random(100, 300) * scale_factor
    elseif side == 2 then -- Right
        x = w + offset
        y = math.random(radius + 50, h - radius - 50)
        dx = -math.random(200, 400) * scale_factor
        dy = -math.random(100, 300) * scale_factor
    elseif side == 3 then -- Top
        x = math.random(radius + 50, w - radius - 50)
        y = -offset
        dx = math.random(-150, 150) * scale_factor
        dy = math.random(200, 400) * scale_factor
    else -- Bottom
        x = math.random(radius + 50, w - radius - 50)
        y = h + offset
        dx = math.random(-150, 150) * scale_factor
        dy = -math.random(200, 400) * scale_factor
    end

    local fruit = {
        x = x, y = y,
        dx = dx, dy = dy,
        dr = math.random(-5, 5),
        rotation = 0,
        radius = fruit_type.radius,
        color = colors.palette[fruit_type.color],
        points = fruit_type.points,
        rare = fruit_type.rare or false,
        name = fruit_type.name,
        slice_count = 0,
        scale = 1
    }
    table.insert(fruits, fruit)
    if fruit.rare then
        createParticleExplosion(fruit.x, fruit.y, {1, 1, 1}, 5, nil, "star")
    end
end

function spawnBomb()
    if game_state == "zen" then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local offset = 30 -- Bomb radius
    local scale_factor = math.min(w / 1920, h / 1080)
    local difficulty_mod = difficulty == "easy" and 0.7 or (difficulty == "hard" and 1.3 or (difficulty == "zen" and 0.5 or 1.0))

    local x = -offset
    local y = h + offset
    local target_x, target_y = w, 0
    local angle = math.atan2(target_y - y, target_x - x) + math.random(-0.2, 0.2)
    local speed = math.random(100, 150) * scale_factor * difficulty_mod
    local dx = math.cos(angle) * speed
    local dy = math.sin(angle) * speed

    table.insert(bombs, {
        x = x, y = y,
        dx = dx, dy = dy,
        dr = math.random(-3, 3),
        rotation = 0
    })
end

function spawnPowerup()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local powerup_type = objects.powerup_types[math.random(1, #objects.powerup_types)]
    local offset = 15 -- Power-up size
    local scale_factor = math.min(w / 1920, h / 1080)
    local difficulty_mod = difficulty == "easy" and 0.7 or (difficulty == "hard" and 1.3 or (difficulty == "zen" and 0.5 or 1.0))

    local x = -offset
    local y = h + offset
    local target_x, target_y = w, 0
    local angle = math.atan2(target_y - y, target_x - x) + math.random(-0.2, 0.2)
    local speed = math.random(100, 150) * scale_factor * difficulty_mod
    local dx = math.cos(angle) * speed
    local dy = math.sin(angle) * speed

    table.insert(powerups, {
        x = x, y = y,
        dx = dx, dy = dy,
        dr = math.random(-3, 3),
        rotation = 0,
        name = powerup_type.name,
        color = powerup_type.color,
        effect = powerup_type.effect,
        duration = powerup_type.duration
    })
end

function checkSlice(point1, point2)
    local powerup_count = 0
    for i = #fruits, 1, -1 do
        local f = fruits[i]
        if lineIntersectsCircle(point1.x, point1.y, point2.x, point2.y, f.x, f.y, f.radius) then
            if f.slice_count < 3 then
                local angle = math.atan2(point2.y - point1.y, point2.x - point1.x)
                sliceFruit(f, angle, i)
                if f.slice_count == 1 then
                    local points = f.points * (1 + objects.combo * 0.3)
                    for _, p in ipairs(objects.active_powerups) do
                        if p.effect == "double" then points = points * 2 end
                    end
                    score = score + math.floor(points)
                    save_and_open_data.set_fruit_coins(save_and_open_data.get_fruit_coins() + f.points)
                end
            else
                table.remove(fruits, i)
            end
            objects.combo = objects.combo + 1
            combo_timer = 2.5
            objects.fruits_sliced = objects.fruits_sliced + 1
            special_move_charge = math.min(100, special_move_charge + 5)
            if sfx_enabled and audio.sound.slash_sound then audio.sound.slash_sound:play() end
            shakeScreen(0.2, 3 + objects.combo * 0.5)
            if life_recovery_timer <= 0 and missed > 0 and math.random() < 0.3 then
                missed = math.max(0, missed - 1)
                life_recovery_timer = 4
                createParticleExplosion(f.x, f.y, {0, 1, 0}, 30, "Life Restored!")
                if sfx_enabled and audio.sound.life_sound then audio.sound.life_sound:play() end
            end
            if objects.combo % 5 == 0 and objects.combo > 0 then
                createParticleExplosion(love.graphics.getWidth()/2, love.graphics.getHeight()/2, {1, 1, 0}, 50, "objects.combo x" .. objects.combo .. "!")
                if sfx_enabled and audio.sound.powerup_sound then audio.sound.powerup_sound:play() end
            end
        end
	end

    for i = #powerups, 1, -1 do
        local p = powerups[i]
        if lineIntersectsCircle(point1.x, point1.y, point2.x, point2.y, p.x, p.y, 15) then
            if p.effect == "life" then
                missed = math.max(0, missed - 1)
            elseif p.effect == "clear" then
                for j = #fruits, 1, -1 do
                    local f = fruits[j]
                    sliceFruit(f, math.random() * math.pi * 2)
                    score = score + math.floor(f.points * (1 + objects.combo * 0.3))
                    save_and_open_data.set_fruit_coins(save_and_open_data.get_fruit_coins() + f.points)
                    objects.fruits_sliced = objects.fruits_sliced + 1
                    table.remove(fruits, j)
                end
                for j = #bombs, 1, -1 do
                    local b = bombs[j]
                    createParticleExplosion(b.x, b.y, {1, 0, 0}, 40)
                    table.remove(bombs, j)
                end
                createParticleExplosion(p.x, p.y, p.color, 50, "Screen Cleared!")
            else
                table.insert(objects.active_powerups, {effect = p.effect, duration = p.duration, color = p.color, name = p.name})
            end
            createParticleExplosion(p.x, p.y, p.color, 30)
            table.remove(powerups, i)
            powerup_count = powerup_count + 1
            if sfx_enabled and audio.sound.powerup_sound then audio.sound.powerup_sound:play() end
            shakeScreen(0.3, 4)
        end
    end

    if powerup_count >= 2 then
        score = score + 50 * powerup_count
        save_and_open_data.set_fruit_coins(save_and_open_data.get_fruit_coins() + 10 * powerup_count)
        createParticleExplosion(love.graphics.getWidth()/2, love.graphics.getHeight()/2, {1, 0, 1}, 50, "Power-Up objects.combo!")
        if sfx_enabled and audio.sound.powerup_sound then audio.sound.powerup_sound:play() end
    end

    for i = #bombs, 1, -1 do
        local b = bombs[i]
        if lineIntersectsCircle(point1.x, point1.y, point2.x, point2.y, b.x, b.y, 20) then
            local has_shield = false
            for _, p in ipairs(objects.active_powerups) do
                if p.effect == "shield" then has_shield = true break end
            end
            if not has_shield then
                score = math.max(0, score - 5)
                if game_state ~= "zen" and game_state ~= "time_attack" then
                    missed = missed + 1
                    objects.combo = 0
                    if missed >= max_missed then 
						game_state = "game_over" 
						if score > (save_and_open_data.get_high_score() or 0) then
							save_and_open_data.set_high_score(score)
						end
						save_and_open_data.save_to_file_progress()
					end
                end
                shakeScreen(0.5, 8)
            end
            createParticleExplosion(b.x, b.y, {1, 0, 0}, 40)
            table.remove(bombs, i)
            if sfx_enabled and audio.sound.bomb_sound then audio.sound.bomb_sound:play() end
        end
    end
end

function sliceFruit(fruit, angle, index)
    if fruit.slice_count >= 3 then return end
    fruit.slice_count = fruit.slice_count + 1
    fruit.sliced = true
    local new_radius = fruit.radius / math.sqrt(2)
    local new_scale = fruit.scale / math.sqrt(2)
    local bonus_points = fruit.slice_count * fruit.points * 0.5

    local img = fruit_sprites[fruit.name]
    local img_w, img_h = img:getWidth(), img:getHeight()
    local quad1 = love.graphics.newQuad(0, 0, img_w / 2, img_h, img_w, img_h) -- Left half
    local quad2 = love.graphics.newQuad(img_w / 2, 0, img_w / 2, img_h, img_w, img_h) -- Right half

    local piece1 = {
        x = fruit.x + math.cos(angle + math.pi/2) * new_radius / 2,
        y = fruit.y + math.sin(angle + math.pi/2) * new_radius / 2,
        dx = fruit.dx + math.cos(angle + math.pi/2) * 100,
        dy = fruit.dy + math.sin(angle + math.pi/2) * 100,
        dr = fruit.dr + math.random(-2, 2),
        rotation = fruit.rotation,
        radius = new_radius,
        color = fruit.color,
        points = fruit.points / 2,
        rare = fruit.rare,
        name = fruit.name,
        slice_count = fruit.slice_count,
        scale = new_scale,
        sliced = true,
        quad = quad1,
        offset_x = -img_w / 4,
        offset_y = -img_h / 2
    }
    local piece2 = {
        x = fruit.x - math.cos(angle + math.pi/2) * new_radius / 2,
        y = fruit.y - math.sin(angle + math.pi/2) * new_radius / 2,
        dx = fruit.dx - math.cos(angle + math.pi/2) * 100,
        dy = fruit.dy - math.sin(angle + math.pi/2) * 100,
        dr = fruit.dr + math.random(-2, 2),
        rotation = fruit.rotation,
        radius = new_radius,
        color = fruit.color,
        points = fruit.points / 2,
        rare = fruit.rare,
        name = fruit.name,
        slice_count = fruit.slice_count,
        scale = new_scale,
        sliced = true,
        quad = quad2,
        offset_x = 0,
        offset_y = -img_h / 2
    }
    table.insert(fruits, piece1)
    table.insert(fruits, piece2)
    if index then
        table.remove(fruits, index)
    end
    createParticleExplosion(fruit.x, fruit.y, fruit.color, 5, nil, fruit.rare and "star")
    local points = bonus_points * (1 + objects.combo * 0.3)
    for _, p in ipairs(objects.active_powerups) do
        if p.effect == "double" then points = points * 2 end
    end
    score = score + math.floor(points)
    save_and_open_data.set_fruit_coins(save_and_open_data.get_fruit_coins() + math.floor(bonus_points))
end

function createParticleExplosion(x, y, color, count, text, shape)
    count = math.min(count, math.max(0, max_particles - #particles))
    if count <= 0 then return end
    for i = 1, count do
        local p
        if #particle_pool > 0 then
            p = table.remove(particle_pool)
            p.active = true
        else
            p = {active = true}
        end
        p.x = x
        p.y = y
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 150)
        p.dx = math.cos(angle) * speed
        p.dy = math.sin(angle) * speed
        p.radius = math.random(2, 4)
        p.color = color
        p.life = math.random(0.3, 1.0)
        p.shape = shape or "circle"
        table.insert(particles, p)
    end
    if text then
        local p
        if #particle_pool > 0 then
            p = table.remove(particle_pool)
            p.active = true
        else
            p = {active = true}
        end
        p.x = x
        p.y = y
        p.dx = 0
        p.dy = -50
        p.radius = 0
        p.color = color
        p.life = 0.8
        p.text = text
        table.insert(particles, p)
    end
end

function shakeScreen(duration, intensity)
    shake_timer = duration
    shake_intensity = intensity
end

function lineIntersectsCircle(x1, y1, x2, y2, cx, cy, r)
    local dx = x2 - x1
    local dy = y2 - y1
    local fx = x1 - cx
    local fy = y1 - cy
    local a = dx * dx + dy * dy
    local b = 2 * (fx * dx + fy * dy)
    local c = fx * fx + fy * fy - r * r
    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then return false end
    discriminant = math.sqrt(discriminant)
    local t1 = (-b - discriminant) / (2 * a)
    local t2 = (-b + discriminant) / (2 * a)
    return (t1 >= 0 and t1 <= 1) or (t2 >= 0 and t2 <= 1)
end

function unlockContent(level)
    if level >= 2 and not blade_sprites.fire then
    end
end

function spawnPowerup()
    local side = math.random(1, 4)
    local x, y, dx, dy
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local powerup_type = objects.powerup_types[math.random(1, #objects.powerup_types)]
    local offset = 15
    local scale_factor = math.min(w / 1920, h / 1080)
    local difficulty_mod = difficulty == "easy" and 0.7 or (difficulty == "hard" and 1.3 or (difficulty == "zen" and 0.5 or 1.0))

    if side == 1 then -- Left
        x = -offset
        y = math.random(50, h - 50)
        dx = math.random(100, 200) * scale_factor * difficulty_mod
        dy = -math.random(80, 150) * scale_factor * difficulty_mod
    elseif side == 2 then -- Right
        x = w + offset
        y = math.random(50, h - 50)
        dx = -math.random(100, 200) * scale_factor * difficulty_mod
        dy = -math.random(80, 150) * scale_factor * difficulty_mod
    elseif side == 3 then -- Top
        x = math.random(50, w - 50)
        y = -offset
        dx = math.random(-80, 80) * scale_factor * difficulty_mod
        dy = math.random(100, 200) * scale_factor * difficulty_mod
    else -- Bottom
        x = math.random(50, w - 50)
        y = h + offset
        dx = math.random(-80, 80) * scale_factor * difficulty_mod
        dy = -math.random(100, 200) * scale_factor * difficulty_mod
    end

    table.insert(powerups, {
        x = x, y = y,
        dx = dx, dy = dy,
        dr = math.random(-3, 3),
        rotation = 0,
        name = powerup_type.name,
        color = powerup_type.color,
        effect = powerup_type.effect,
        duration = powerup_type.duration
    })
end

function love.quit()
    save_and_open_data.save_to_file_progress()
    return false
end
