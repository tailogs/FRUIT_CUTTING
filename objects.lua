return {
    fruit_types = {
        {name = "Apple", radius = 25 * 5, points = 1, color = 1},
        {name = "Banana", radius = 30 * 5, points = 2, color = 4},
        {name = "Blueberry", radius = 15 * 5, points = 3, color = 3},
        {name = "Orange", radius = 28 * 5, points = 1, color = 5},
        {name = "Grape", radius = 20 * 5, points = 2, color = 6},
        {name = "Golden Fruit", radius = 22 * 5, points = 10, color = 7, rare = true}
    },

    powerup_types = {
        {name = "SlowTime", color = {0.5, 0.5, 1}, effect = "slow", duration = 7},
        {name = "DoubleScore", color = {1, 1, 0}, effect = "double", duration = 10},
        {name = "ExtraLife", color = {0, 1, 0}, effect = "life", duration = 0},
        {name = "Frenzy", color = {1, 0, 1}, effect = "frenzy", duration = 8},
        {name = "Shield", color = {0.7, 0.7, 0.7}, effect = "shield", duration = 12},
        {name = "ClearWave", color = {1, 0.5, 0.5}, effect = "clear", duration = 0}
    },

    achievements = {
        {name = "Fruit Ninja", desc = "Slice 100 fruits", goal = 100, progress = 0, unlocked = false},
        {name = "Combo Master", desc = "Reach combo x10", goal = 10, progress = 0, unlocked = false}
    },
	
    active_powerups = {},
	fruits_sliced = 0,
	combo = 0,
	
	checkAchievements = function(self)
		self.achievements[1].progress = self.fruits_sliced
		if self.fruits_sliced >= self.achievements[1].goal then
			self.achievements[1].unlocked = true
		end
		
		self.achievements[2].progress = math.max(
			self.achievements[2].progress, 
			self.combo
		)
		if self.combo >= self.achievements[2].goal then
			self.achievements[2].unlocked = true
		end
	end
}