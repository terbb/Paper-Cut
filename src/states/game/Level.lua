Level = class("Level"):include(Observable):include(Observer)
Level.static.MAX_SCORE = 200
Level.static.INITIAL_TARGET = 600
Level.static.EVERY_X_DIFFICULTY = 3
Level.static.STARTING_TIME = 60
Level.static.MIN_SHAPE_DIMEN = 1
Level.static.MAX_SHAPE_DIMEN = 6
Level.static.POINTS_TO_END_TUTORIAL = 800
Level.static.TARGET_MULTIPLIER = 0.50
Level.static.SHAPE_COMPLETED = "SHAPE_COMPLETED"
Level.static.START = "START"
Level.static.UNLOCKED_SHAPE = "UNLOCKED_SHAPE"
Level.static.CHARGE = false
Level.static.MAX_CHARGE = 30

function Level:initialize(mode)
  self.mode = mode
  if mode == "Baby" then
    self.grid = Grid()
    self.tutorial = true
    self.shapes = {"Rectangle"}
    self.nextShape = "Oval"
    Level.static.TARGET_MULTIPIER = 0.4
    Level.static.INITIAL_TARGET = 500
  end
  
  if mode == "Normal" then
    self.tutorial = false
    self.shapes = {"Rectangle"}
    self.nextShape = "Oval"
    Level.static.TARGET_MULTIPLIER = 0.5
    Level.static.INITIAL_TARGET = 600
  end
  
  if mode == "Veteran" then
    self.tutorial = false
    self.shapes = {"Rectangle", "Oval", "Triangle", "Diamond"}
    self.nextShape = "none"
    Level.static.TARGET_MULTIPLIER = 0.6
    Level.static.INITIAL_TARGET = 800
  end
  self.total = 0
  self.iteratedTotal = 0
  self.iterate = false
  self.differenceToIterate = 0
  self.currentStatus = false
  self.target = Level.INITIAL_TARGET
  self.timer = Timer()
  self.timer:registerObserver(self)
  self.combo = Combo()
  self.popUps = {}
  self.speech = Speech()
  self.difficulty = 1
  self.problem = false
  self:generateProblem()
  self.targetsUntil = Level.static.EVERY_X_DIFFICULTY
  self.scoreText = TextPlaceable("Score: ", Point(baseRes.width * 0.05, baseRes.height * 0.8))
  self.scoreCounter = TextPlaceable("1")
  self.scoreCounter:setRight(self.scoreText, 0)
  self.scoreCounter:setPosition(Point(self.scoreCounter.position.x, baseRes.height * 0.8))
  self.targetCounter = TextPlaceable("Target: ", Point(baseRes.width * 0.05, baseRes.height * 0.9), nil, nil, 0.5)
  self.targetCounter:setBelow(self.scoreText, 2)
  self.targetsUntilShape = TextPlaceable(("In %i targets: %s"):format(self.targetsUntil, self.nextShape), nil, nil, nil, 0.5)
  self.charge = Level.CHARGE
  self:registerObserver(user)
  if self.mode ~= "Baby" then
    self:notifyObservers(Level.START)
  end
end

function Level:update(dt)
  self.timer:update(dt)
  if self.nextShape == "none" then self.targetsUntilShape:update(dt, "All shapes added.") else 
    if self.targetsUntil > 1 then
      self.targetsUntilShape:update(dt, ("%i targets unlocks: %s"):format(self.targetsUntil, self.nextShape))
    else
      self.targetsUntilShape:update(dt, ("Next target unlocks: %s"):format(self.nextShape))     
    end
  end
  self.targetsUntilShape:setLeftOfPoint(Point(baseRes.width * 0.96, 60))
  for i = 1, #self.popUps do
    local popUp = self.popUps[i]
    if popUp ~= nil then 
      popUp:update(dt)
      if popUp.alpha < 0 then self.popUps[i] = nil end
    end
  end
  self.speech:update(dt)
  
  if self.iterate then 
    self.iteratedTotal = self.iteratedTotal + self.differenceToIterate
    if self.differenceToIterate > 0 then
      if self.iteratedTotal >= self.total then 
        self.iterate = false 
        self.iteratedTotal = self.total
        self.scoreCounter:setColor(Graphics.NORMAL)
      end
    else
      if self.iteratedTotal <= self.total then 
        self.iterate = false 
        self.iteratedTotal = self.total
        self.scoreCounter:setColor(Graphics.NORMAL)
      end
    end
  end
  
  self.scoreCounter:update(dt, self.iteratedTotal)
  self.scoreText:update()
  self.targetCounter:update(dt, "Next target: " .. self.target)  
  if self.currentStatus then
    self.currentStatus:update(dt)
  end
end

function Level:draw()
  if self.grid then self.grid:draw() end
  self.timer:draw()
  self.speech:draw()
  for i = 1, #self.popUps do
    local popUp = self.popUps[i]
    if popUp ~= nil then popUp:draw() end
  end
  self.problem:draw()
  self.scoreCounter:draw()  
  self.scoreText:draw()
  self.targetCounter:draw()
  self.targetsUntilShape:draw()
  if self.charge then self:drawChargeBar() end
  if self.currentStatus then self.currentStatus:draw() end
end

function Level:scoreDrawing(drawing)
  local charge = Level.CHARGE -- get charge level of laser before resetting to 0
  local score, successPercentage = self.problem:score(drawing)
  local comboMultipliedScore = math.floor(self.combo:multiply(score, successPercentage))
  modifiedScore = self:modifyScore(comboMultipliedScore)
  if self.currentStatus then 
    self.currentStatus:decrementTimer() 
    if self.currentStatus.timer == 0 then 
      self.currentStatus = nil 
    else
      modifiedScore = self.currentStatus:modifyScore(modifiedScore)
    end
  end
  local rating = RatingFactory:rate(modifiedScore)
  self.speech = Speech(rating.text, rating.color)
  if (tostring(rating) == "BadRating" and self.tutorial) then
    self.speech:setText("(Trace the shape to get points!)")
    self.speech:setColor(Graphics.YELLOW)
  end
    
  local scorePopUp = NumberPopUp(modifiedScore, rating.color, 1, Point.centreOf(self.problem.bounds, self.problem.dimensions))

  local comboPopUp = TextPopUp("x" .. self.combo.multiplier, Graphics.NORMAL, 1, false)
  comboPopUp.position.x = scorePopUp.position.x
  comboPopUp:setAbove(scorePopUp)

  if self.combo.multiplier >= 2.5 then
    local fire = love.graphics.newImage("assets/graphics/game/hud/icon_combo.png")
    local fireAmount = self.combo.multiplier * 2.5
    if fireAmount >= 100 then fireAmount = 100 end
    local fireSystem = love.graphics.newParticleSystem(fire, fireAmount)
    fireSystem:setParticleLifetime(1, 2)
    fireSystem:setEmissionRate(fireAmount)
    fireSystem:setSizeVariation(1)
    fireSystem:setLinearAcceleration(-120, -120, 120, 120)
    fireSystem:setEmissionArea("borderellipse", 65, 65, 0, false)
    fireSystem:setSizes(0.75, 1.25, 0.85, 0.65, 0.5, 1, 0.3, 1.5)
    fireSystem:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.
    
    local firePopUp = ParticleSystemPopUp(fireSystem, Graphics.NORMAL, 1, false)
    firePopUp:setPosition(Point(comboPopUp.position.x + 35, comboPopUp.position.y + 35))
    table.insert(self.popUps, firePopUp)  
  end
  
  table.insert(self.popUps, comboPopUp)
  table.insert(self.popUps, scorePopUp)

  self:addScore(modifiedScore)
  local oldTargetUps = self.difficulty - 1
  local timeLeft = self.timer.time
  
  if self:isTutorialOver() then 
    self.tutorial = false 
  end
  while self:isTargetAchieved() do
    Sound:createAndPlay("assets/audio/sfx/sfx_targetup.wav", "targetup")
    local targetUpPopUp = TextPopUp("Target Up!", Graphics.YELLOW, 1, false)
    targetUpPopUp.position.x = scorePopUp.position.x
    targetUpPopUp:setBelow(self.popUps[#self.popUps])
    table.insert(self.popUps, targetUpPopUp)
    self.timer:resetTimer()
    self:increaseTarget()
    self:increaseDifficulty()
end

  local data = {shape = tostring(self.problem), accuracy = successPercentage * 100, tutorial = self.tutorial, points = modifiedScore, targetUpsThisScore = (self.difficulty - 1) - oldTargetUps, timeLeft = timeLeft, rating = rating.text, timePlayed = self.timer.timePlayed, multiplier = self.combo.multiplier, targetUps = self.difficulty - 1, mode = self.mode, status = self.currentStatus, scissors = user.currentEffect.name, charge = charge, totalScore = self.total}

  self.problem.displayAnswer = true
  Sound:play(rating.soundTag)
  if self.mode ~= "Baby" then
    self:notifyObservers(Level.SHAPE_COMPLETED, data)   
  end
  
  self:onScore(modifiedScore, tostring(self.problem), successPercentage)
end

function Level:addScore(score)
  self.total = self.total + score
  self.differenceToIterate = (self.total - self.iteratedTotal) * 0.1
  if self.differenceToIterate > 0 then self.differenceToIterate = math.ceil(self.differenceToIterate) else self.differenceToIterate = math.floor(self.differenceToIterate) end
  if self.differenceToIterate > 0 then self.scoreCounter:setColor(Graphics.GREEN) else self.scoreCounter:setColor(Graphics.RED) end
  self.iterate = true
end

function Level:generateWidthAndHeight()
  local randWidth = love.math.random(Level.MIN_SHAPE_DIMEN, Level.MAX_SHAPE_DIMEN)
  local randHeight = love.math.random(Level.MIN_SHAPE_DIMEN, Level.MAX_SHAPE_DIMEN)
  return randWidth, randHeight
end

function Level:generateProblem()
  local randWidth, randHeight = self:generateWidthAndHeight()
  local shape = self.shapes[love.math.random(1, #self.shapes)]

  if shape == "Rectangle" then
    self.problem = Rectangle(randWidth, randHeight, Level.MAX_SCORE)
  elseif shape == "Oval" then
    self.problem = Oval(randWidth, randHeight, Level.MAX_SCORE)
  elseif shape == "Triangle" then
    self.problem = Triangle(randWidth, randHeight, Level.MAX_SCORE)
  elseif shape == "Diamond" then
    self.problem = Diamond(randWidth, randHeight, Level.MAX_SCORE)
  end
  
  if self.tutorial then 
    self.problem.displayAnswer = true 
    self.speech = Speech(("Cut out this %iW x %iL %s!"):format(randWidth, randHeight, shape))
  else
    self.speech = Speech(("I need a %iW x %iL %s!"):format(randWidth, randHeight, shape))
  end
end

function Level:onScore(score)
end

function Level:modifyScore(score)
  return score
end

function Level:isTargetAchieved()
  return self.total >= self.target 
end

function Level:isTutorialOver()
  return self.total >= Level.POINTS_TO_END_TUTORIAL
end

function Level:increaseTarget()
  self.target = math.floor(self.target + self.target * Level.TARGET_MULTIPLIER)
end

function Level:increaseDifficulty()
  self.difficulty = self.difficulty + 1
  self.targetsUntil = self.targetsUntil - 1
  if self.targetsUntil == 0 then 
    self.targetsUntil = Level.static.EVERY_X_DIFFICULTY
    self:addNewShape() 
  end  
end

function Level:addNewShape()
  local shapesAdded = #self.shapes
  if self.mode ~= "Baby" then
    self:notifyObservers(Level.UNLOCKED_SHAPE, {shape = self.nextShape})
  end
  if shapesAdded == 1 then
    self.shapes[shapesAdded + 1] = "Oval"
    self.nextShape = "Triangle"
  elseif shapesAdded == 2 then
    self.shapes[shapesAdded + 1] = "Triangle"
    self.nextShape = "Diamond"
  elseif shapesAdded == 3 then
    self.shapes[shapesAdded + 1] = "Diamond"
    self.nextShape = "none"
  end
  
  if shapesAdded < 4 then
    local popUp = TextPopUp(("%ss added!"):format(self.shapes[#self.shapes]), Graphics.NORMAL, 1, mouseCoord)
    popUp:setBelow(self.popUps[#self.popUps])
    popUp.position.x = self.popUps[#self.popUps].position.x  
    table.insert(self.popUps, popUp)
  end
end

function Level:notify(event)
  if event == Timer.OUT_OF_TIME then
    if self.mode ~= "Baby" then
      self:notifyObservers(Timer.OUT_OF_TIME, {timePlayed = self.timer.timePlayed, totalScore = self.total, mode = self.mode, scissors = user.currentEffect.name})    
    end
    highScore:attemptToAddScore(self.total)
    highScore:saveScores()
    state = GameOver(self.total)
  end
end