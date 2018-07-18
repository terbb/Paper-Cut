Level = class("Level", {MAX_SCORE = 160, INITIAL_TARGET = 500, EVERY_X_DIFFICULTY = 3, STARTING_TIME = 60, MAX_SHAPE_DIMEN = 6})

function Level:init()
  self.total = 0
  self.target = Level.INITIAL_TARGET
  self.timer = Timer()
  self.combo = Combo()
  self.popUps = {}
  self.speech = Speech()
  self.difficulty = 1
  self.problem = false
  self.shapes = {"rectangle"}
end

function Level:update(dt)
  for i, popUp in ipairs(self.popUps) do
    popUp:update()
    if popUp.alpha < 0 then table.remove(self.popUps, i) end
  end
  self.timer:update(dt)
end

function Level:draw()
  self.speech:draw()
  for _, popUp in ipairs(self.popUps) do
    popUp:draw()
  end
  self.problem:draw()
  self.timer:draw()
  Graphics:drawText("Score: " .. self.total, baseRes.width * 0.6, baseRes.height * 0.9, "left", Graphics.NORMAL)
  Graphics:drawText("Target: " .. self.target, baseRes.width * 0.2, baseRes.height * 0.9, "left", Graphics.NORMAL)
end


function Level:scoreDrawing(drawing)
  local score = self.problem:score(drawing)
  local comboMultipliedScore = math.floor(self.combo:multiply(score))  
  local rating = RatingFactory:rate(comboMultipliedScore)
  self.speech = Speech(rating.text, rating.color)
  
  local scorePopUp = NumberPopUp(comboMultipliedScore, rating.color, 1, Scale:getWorldMouseCoordinates())
  local comboPopUp = TextPopUp("x" .. self.combo.multiplier, Graphics.NORMAL, 1, false)
  comboPopUp.position.x = scorePopUp.position.x
  comboPopUp:setAbove(scorePopUp)
  table.insert(self.popUps, scorePopUp)
  table.insert(self.popUps, comboPopUp)
  
  if self.combo.multiplier > 2 then
    local firePopUp = ImagePopUp("assets/graphics/game/hud/icon_combo.png", Graphics.NORMAL, 0.30, false)
    firePopUp:setLeft(comboPopUp, 0)
    firePopUp:setCentreVertical(comboPopUp)
    table.insert(self.popUps, firePopUp)
  end

  self.total = self.total + comboMultipliedScore
  
  if self:isTargetAchieved() then
    local targetUpPopUp = TextPopUp("Target Up!", Graphics.YELLOW, 1, false)
    targetUpPopUp.position.x = scorePopUp.position.x
    targetUpPopUp:setBelow(scorePopUp)
    table.insert(self.popUps, targetUpPopUp)
    
    self.timer:resetTimer()
    self:increaseTarget()
    self:increaseDifficulty()
  end
  
  self.problem.displayAnswer = true
  Sound:createAndPlay(rating.sound.path, rating.sound.name)
end

function Level:generateProblem()
  local randWidth = love.math.random(Level.MAX_SHAPE_DIMEN) / 2
  local randHeight = love.math.random(Level.MAX_SHAPE_DIMEN) / 2
  local shape = self.shapes[love.math.random(1, #self.shapes)]

  if shape == "rectangle" then
    self.problem = Rectangle(randWidth, randHeight, Level.MAX_SCORE)
  elseif shape == "oval" then
    self.problem = Oval(randWidth, randHeight, Level.MAX_SCORE)
  elseif shape == "triangle" then
    self.problem = Triangle(randWidth, randHeight, Level.MAX_SCORE)
  end
  
  self.speech = Speech("I need a " .. randWidth .. "W" .. " x " .. randHeight .. "L" .. " " .. self.problem.name .. "!", Graphics.NORMAL)
end

function Level:isTargetAchieved()
  return self.total >= self.target 
end

function Level:increaseTarget()
  self.target = self.target + self.target * 0.5
end

function Level:increaseDifficulty()
  self.difficulty = self.difficulty + 1
  if self.difficulty % Level.EVERY_X_DIFFICULTY == 0 then self:addNewShape() end  
end

function Level:addNewShape()
  if self.shapes[2] == nil then self.shapes[2] = "oval" return end
  if self.shapes[3] == nil then self.shapes[3] = "triangle" return end
end
