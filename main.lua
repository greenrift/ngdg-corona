--hide the status bar
display.setStatusBar( display.HiddenStatusBar )

local physics = require("physics")
physics.start()
--adjust the physics scale to make it a little less challenging
--lower numbers are slower, higher numbers are faster
physics.setScale( 10 )
local removeBall = nil
local ballTimer = nil -- timer for ball generation.  Use variable so we can cancel it at game over
local isGameOver = false

local screen = {
	left = display.screenOriginX,
	top = display.screenOriginY,
	right = display.contentWidth - display.screenOriginX,
	bottom = display.contentHeight - display.screenOriginY,
	middleX = display.contentWidth * 0.5,
	middleY = display.contentHeight * 0.5,
    width = display.contentWidth,
    height = display.contentHeight,
}

local totalscore = 0

local header_group = display.newGroup()
local score_text = display.newText("Score: " .. totalscore, 0, 0, native.systemFont, 20)
score_text:setReferencePoint(display.TopLeftReferencePoint)
score_text.x = 5
score_text.y = 0
header_group:insert(score_text)

--keep list of count of balls remaining
local balls_remaining = {}
--create a group to organize status balls
local ball_group = display.newGroup()
--create 3 balls at top to signify balls left to lose
for i = 1, 3 do
	local rem = display.newCircle(0, 0, 10)
	rem:setReferencePoint(display.CenterLeftReferencePoint)
	rem.x = ball_group.width
	rem.y = 0
	ball_group:insert(rem)
	table.insert(balls_remaining, rem)
end
ball_group:setReferencePoint(display.TopRightReferencePoint)
ball_group.x = screen.right - 5
ball_group.y = 0
header_group:insert(ball_group)

--place the header group on the screen.
header_group:setReferencePoint(display.TopCenterReferencePoint)
header_group.x = screen.middleX
header_group.y = screen.top

--value used to place all screen items below so as to not overlap with the score and status area.
local header_y = header_group.y + header_group.height

--update the score based on ball value
local function updateScore(val)
	totalscore = totalscore + val
	score_text.text = "Score: " .. totalscore
	--ensure score text location doesn't appear to "wobble"
	score_text:setReferencePoint(display.TopLeftReferencePoint)
	score_text.x = 5
end

--left wall
local left = display.newRect(0, header_y, 10, screen.bottom)
physics.addBody(left, "static")

--right wall
local right = display.newRect(screen.right - 10, header_y, 10, screen.bottom)
physics.addBody(right, "static")

--add "sensor" bar at bottom to detect when balls are missed
local bottom = display.newRect(0, screen.bottom, screen.right, screen.bottom + 1)
physics.addBody(bottom, "static", {isSensor = true})

--bucket to catch balls
local bucket = display.newRect( 0, 0, 100, 10 )
bucket.x = screen.middleX
bucket.y = screen.bottom - 50
--assign to physics as sensor.  We don't want it to interact...just absorb balls.
physics.addBody(bucket, "static", {isSensor = true})

--specifiy restrictions for our randomly generated slanty platforms
local minWidth = 10
local maxWidth = 50
local minRot = -50
local maxRot = 50
--generate 10 slanty platforms of varying length
for i = 1, 10 do

	local blah = display.newRect(0, 0, 
	       math.random(minWidth, maxWidth), 10)
	--calculate 1/2 of the width so we can make sure the platforms are all on the screen between the walls.
	local half_blah = blah.width * 0.5
	blah.x = math.random(screen.left + 10 + half_blah, screen.right - 10 - half_blah)
	blah.y = math.random(header_y + 5, screen.bottom - 75)
	--save rotation value for later use
	blah.rotationval = math.random(minRot, maxRot)
	--rotate
	blah:rotate(blah.rotationval)
	physics.addBody(blah, "static")

	--function to handle rotation when timer below executes.
	local function rotateBlah()
		local rotval = blah.rotationval
		rotval = rotval * -1
		blah.rotationval = rotval
		transition.to(blah, {time=1000, rotation = rotval})
	end
	-- set a never ending timer to auto rotate the bars left and right.
	timer.performWithDelay(5000, rotateBlah, 0)
end

--function to remove the balls.
removeBall = function(obj)
	if(obj ~= nil and obj.isVisible ~= nil) then
		display.remove(obj)
		obj = nil
	end
end

--called when game is over
local function gameOver()
	timer.cancel(ballTimer)
	local status = display.newText("GAME OVER", 0, 0, native.systemFont, 40)
	status.x = screen.middleX
	status.y = screen.middleY
	status:setTextColor(math.random(255), math.random(255), math.random(255))
	isGameOver = true
end


--handler to handle collision between bucket and balls
local function bucketCollision(self, event)
	if(event.phase == "began" and not isGameOver) then
		--remove ball
		if(event.other ~= nil) then
			updateScore(event.other.points)
			timer.performWithDelay(0, 
			     function() return removeBall(event.other) end, 1)
		end
	end
	return true
end
bucket.collision = bucketCollision
bucket:addEventListener("collision", bucket)

--handler to detect bottom of the screen sensor
local function bottomCollision(self, event)
	if(event.phase == "began" and not isGameOver) then
		--remove ball from status at top
		local remball = table.remove(balls_remaining)
		display.remove(remball)
		remball = nil
		if(#balls_remaining == 0) then
			gameOver()
		end
	end
	return true
end
bottom.collision = bottomCollision
bottom:addEventListener("collision", bottom)

--move the bucket as you drag your finger on the screen.
--left and right movement.  We don't care if it goes off the screen.
local function moveBucket(event)
	bucket.x = event.x
end

--function to generate a random sized/colored ball.
local function generateBall()
	local ball = display.newCircle( -10, -10, math.random(5, 10) )
	ball.x = math.random(screen.left + 20, screen.right - 20)
	ball:setFillColor(math.random(255), math.random(255), math.random(255))
	--assign ball points based on radius. Take ceiling to ensure integer
	ball.points = math.ceil(ball.width * 0.5)
	--since it's a ball, set the radius with the addBody
	physics.addBody(ball, "dynamic", {radius = ball.width * 0.5})
end

--start the ball generation timer generating a ball every 1 sec.
ballTimer = timer.performWithDelay( 1000, generateBall, 0 )

--event listener "touch" set for whole screen to detect bucket movement.
Runtime:addEventListener("touch", moveBucket)