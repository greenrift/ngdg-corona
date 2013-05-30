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

local hello = display.newText("Hello World!", 0, 0, system.nativeFont, 40)
hello.x = screen.middleX
hello.y = screen.middleY