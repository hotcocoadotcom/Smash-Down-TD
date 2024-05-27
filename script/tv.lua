-- simple teardown video player by cheeekin --
-- updated 2/15/2022 to add distance culling.

-- how to add your own video --
-- 1: get a video
-- 2: scale the video to fit your screen
-- 3: extract all the frames with ffmpeg
-- 4: extract ONLY the audio with ffmpeg and save it as a ogg file (ffmpeg likes to include video in the ogg file so make sure to use the -vn argument) and replace monitor0.ogg
-- 5: then set the below parameters to match your setup (length is the #frames in your frames folder)
-- 6: then boom you have a working video player in teardown!
local playing = true
local dist = 0
local self = {}
local snd = {}

function init()
    current = 0
    t = 0
	-- video parameters --
    fps = 1
    length = 574
	PlaybackDistance = 10000
	finished = false
	sndplayed = false
    ----------------------
    framerate = (1/60)*(60/fps)
	snd = LoadLoop("MOD/herald/herald.ogg")
end

function tick()
	local pos = GetShapeWorldTransform(GetScreenShape(self)).pos
	local plrPos = GetPlayerPos()
	playing = dist < PlaybackDistance and dist > -PlaybackDistance
	if not IsScreenEnabled(self) then
		current = 0
		t = 0
		finished = false
		sndplayed = false
	end
	if IsScreenEnabled(self) then
		PlayLoop(snd, pos)
	end
end

function draw()
	self = UiGetScreen()
	if playing then
		t = t + GetTimeStep()
    end
	if dist < PlaybackDistance*2 and dist > -PlaybackDistance*2 and not finished then
		if math.floor(t/framerate)>length then
			finished = true
		end
		
		current = math.floor(t/framerate)
		
		UiTranslate(UiCenter(), UiMiddle())
		UiAlign("center middle")
		UiImage("MOD/herald/"..current..".png")
	end
end
function getFullName(rootname,num)
    return rootname..num
end