title = GetStringParam("title", "")
desc = GetStringParam("desc", "")
descr = GetFloatParam("r", 255)
descg = GetFloatParam("g", 255)
descb = GetFloatParam("b", 255)

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
    UiFont("bold.ttf", 192)
    UiText(title)
    UiTranslate(0, 72)
    UiFont("regular.ttf", 48)
    UiColor(descr/255, descg/255, descb/255, uiCloseEyes)
    UiText(desc)
    end
end