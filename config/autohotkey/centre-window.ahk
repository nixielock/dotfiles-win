; centre window for triple monitor setup
; keybind: win+alt+c
#!c::{ 
	monitorCount := MonitorGetCount()
	WinGetPos &posX, &posY, &width, &height, "A"
	WinGetClientPos &clPosX,,,, "A" ; use client X coordinate for better edge detection
	if (clPosX < 0) {
		; loop through monitors to locate right monitor
		; (aka position of left edge is negative)
		loop monitorCount {
			MonitorGetWorkArea A_Index, &minX, &minY, &maxX, &maxY
			if (minX < 0) {
				targetX := (maxX / 2) + (minX / 2) - (width / 2)
				targetY := (minY / 2) + (maxY / 2) - (height / 2)
				WinMove targetX, targetY,,, "A"
				break
			}
		}
	} else if (clPosX < A_ScreenWidth) {
		; centre monitor starts with left edge at 0, so no adjustment
		WinMove (A_ScreenWidth/2) - (width/2), (A_ScreenHeight/2) - (height/2),,, "A"
	} else {
		; loop through monitors to locate right monitor
		; (aka position of left edge is greater than zero)
		loop monitorCount {
			MonitorGetWorkArea A_Index, &minX, &minY, &maxX, &maxY
			if (minX > 0) {
				targetX := (minX / 2) + (maxX / 2) - (width / 2)
				targetY := (minY / 2) + (maxY / 2) - (height / 2)
				WinMove targetX, targetY,,, "A"
				break
			}
		}
	}
}
