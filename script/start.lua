title = GetStringParam("title", "")
desc = GetStringParam("desc", "")
music = GetStringParam("music", "")
descr, descg, descb = GetColorParam("desc-color", 1, 1, 1)

function init()
    uiCloseEyes = 1
    uiStart = false
    uiClosed = false
    
end

function tick(dt)
    if GetTime() > 0 and not tp then
        SetPlayerTransform(Transform(Vec(0, 1000, 0)))
        tp = true
    end
    if GetTime() > 2 and not uiStart then
        PlayMusic("MOD/music/"..music)
        uiStart = true
    end
    if GetTime() > 6 and not uiClosed then
        RespawnPlayer()
        SetValue("uiCloseEyes", 0, "linear", 3)
        uiClosed = true
    end

    if uiCloseEyes > 0.2 then
        SetBool("hud.disable", true)
    end
end

function draw()
	UiColor(0,0,0,uiCloseEyes)
	UiRect(UiWidth(),UiHeight())
    if uiStart then
    UiColor(1,1,1,uiCloseEyes)
    UiAlign("center middle")
    UiTranslate(UiCenter(), UiMiddle())
    UiFont("MOD/font/bold.ttf", 160)
    UiText(title)
    UiTranslate(0, 128)
    UiFont("MOD/font/regular.ttf", 48)
    UiColor(descr, descg, descb, uiCloseEyes)
    UiText(desc)
    end
end