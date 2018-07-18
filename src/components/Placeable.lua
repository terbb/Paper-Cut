Placeable = class("Placeable"):with(Orientation)

function Placeable:init(position)
  self.position = position or Point()
end

function Placeable:draw()
  error("Cannot draw an unspecified Placeable!")
end

ImagePlaceable = Placeable:extend("ImagePlaceable")

function ImagePlaceable:init(path, position)
  ImagePlaceable.super.init(self, position)       
  self.image = path and love.graphics.newImage(path) or false
  self.dimensions = self.image and Dimensions(self.image:getWidth(), self.image:getHeight()) or Dimensions()
end

function ImagePlaceable:draw()
  Graphics:draw(self.image, self.position.x, self.position.y, Graphics.NORMAL)           
end


TextPlaceable = Placeable:extend("TextPlaceable")

function TextPlaceable:init(text, position, align, color)
  TextPlaceable.super.init(self, position)
  self.text = text or ""
  self.dimensions = Dimensions(font:getWidth(self.text), font:getHeight(self.text))
  self.align = align or "left"
  self.color = color or Graphics.NORMAL 
end

function TextPlaceable:draw()
  Graphics:drawText(self.text, self.position.x, self.position.y, self.align, self.color)
end

FlashingTextPlaceable = TextPlaceable:extend("FlashingTextPlaceable")

function FlashingTextPlaceable:init(text, position, align, color, cycle)
  FlashingTextPlaceable.super.init(self, text, position, align, color)
  self.baseColor = self.color
  self.counter = 0
  self.cycle = cycle or 15
  self.alpha = 0.25  
end

function FlashingTextPlaceable:update(dt)
  self.counter = (self.counter + 1) % (self.cycle + 1)
  if self.counter == self.cycle then 
    if self.color == self.baseColor then 
      self.color = Graphics:modifyColorAlpha(self.color, self.alpha) 
    else 
      self.color = self.baseColor 
    end
  end
end

function FlashingTextPlaceable:draw()
  FlashingTextPlaceable.super.draw(self) 
end