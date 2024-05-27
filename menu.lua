#include "automatic.lua"
function init()
    dodraw = true
    bgfrac = 1
    offset = 0
    optionoffset = 0
    optiontab = false
    slider = 0
    slider2 = 5
    clicksnd = LoadSound("MOD/snd/click.ogg")

    buttons = {}
    sliders = {}
end

function tick()
    SetBool("game.disablepause", true)
    SetBool("game.disablemap", true)
    RespawnPlayer()

    if offset > 0 then
        PlayMusic("MOD/music/menu/regular.ogg")
    end
    if ( GetTime() > 10 or InputPressed("any") ) and not fadein then
        SetValue("bgfrac", 0, "cosine", 2.4)
        SetValue("offset", splithor, "easeout", 1.2)
        fadein = true
        if math.random(1,20) == 1 then
            PlaySound(LoadSound("MOD/snd/SPACE.ogg"))
        end
    end
    SetBool("hud.disable", true)

    if InputPressed("esc") then
       Menu()
    end
end

function draw()
    splithor = UiWidth() / 4
    splitver = UiHeight() / 1.5
    UiPush()

    UiPush()
        UiColor(0, 0, 0, bgfrac)
        UiRect(UiWidth(), UiHeight())
    UiPop()

    UiPush()
        if offset < splithor then
            UiAlign("center middle")
            UiTranslate(UiCenter(), UiMiddle())
            UiColor(1,1,1,-offset/splithor+1)
            UiImageBox("MOD/images/hotlogo.png", UiHeight()/2, UiHeight()/4)
            UiColor(1,1,1,(1-math.sin(GetTime()*2)/4) * (-offset/splithor+1))
            UiFont("regular.ttf", 24)
            UiTranslate(0, UiHeight()/6)
            UiText("PRESS ANY KEY TO CONTINUE...")
        end
    UiPop()
    if dodraw then
        if offset > 0 then
            UiMakeInteractive()
        end

        UiPush()
        UiTranslate(-splithor + offset)
        UiTranslate(24, 24)
        UiPush()
            UiColor(0, 0, 0, 0.85)
            UiRoundedRect(splithor - 48, UiHeight() - 48, 8)
        UiPop()
        UiTranslate(24, 24)
        UiImageBox("MOD/images/logo.png", 384, 96)

        UiTranslate(24, 192)
        
        UiButtonImageBox("ui/common/box-outline-6.png", 8, 8)
        UiButtonHoverColor(0.3, 0.85, 1)
        UiButtonPressColor(0.24, 0.68, 0.8)
        UiFont("regular.ttf", 28)

        if UiTextButton("Start New Game") then
            PlaySound(clicksnd)
            StartLevel("", "MOD/checkpoint0.xml")
        end
        UiTranslate(0, 60)
        if UiTextButton("Continue Game") then
            PlaySound(clicksnd)
            --continues game
        end
        UiTranslate(0, 60)
        if UiTextButton("Options") then
            PlaySound(clicksnd)
            optiontab = not optiontab
            ToggleOptions()
        end
        UiTranslate(0, 84)
        if UiTextButton("Close") then
            PlaySound(clicksnd)
            Menu()
        end

        UiPop()

        UiPush()
        UiTranslate(splithor*4 + optionoffset)
        UiTranslate(24, 24)
        UiPush()
            UiColor(0, 0, 0, 0.85)
            UiRoundedRect(splithor - 48, UiHeight() - 48, 8)
        UiPop()
        UiAlign("top right")
        UiTranslate(splithor-72, 24)
        UiImageBox("MOD/images/options.png", 384, 96)

        UiTranslate(-24, 192)
        
        UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
        UiButtonHoverColor(0.3, 0.85, 1)
        UiButtonPressColor(0.24, 0.68, 0.8)
        UiFont("regular.ttf", 28)

        if UiTextButton("Option Thing") then
            PlaySound(clicksnd)
            --new game
        end
        UiTranslate(0, 80)
        slider = Slider("example", slider, 0, 10, 1, 320)
        UiTranslate(0, 80)
        slider2 = Slider("example again", slider2, 4, 20, 2, 320)
        UiTranslate(0, 80)
        buttoner = ToggleButton("Button", buttoner)
        UiTranslate(0, 100)
        buttoner2 = ToggleButton("Another Button", buttoner2)
        UiPop()
    end
end

function ToggleOptions()
    if optiontab then
        SetValue("optionoffset", -splithor, "easeout", 0.5)
    else
        SetValue("optionoffset", 0, "easein", 0.3)
    end
end

function Slider(title, value, min, max, increment, width)
    sliders[title] = width/max
    UiPush()
    UiColor(0.3, 0.85, 1)
    UiTranslate(-width, 0)
    UiAlign("right middle")
    UiTranslate(-8, 32)
    UiRect(-width, 3)
    UiTranslate(8, 0)
    value = UiSlider("ui/common/dot.png", "x", value*sliders[title], min, width) / sliders[title]
    value = AutoRound(value, increment)
    UiAlign("right middle")
    UiTranslate(width - 8, -32)
    UiFont("regular.ttf", 24)
    UiColor(1, 1, 1)
    UiText(title.." - "..value)
    UiPop()
    return value
end

function ToggleButton(title, value)
    if buttons[title] == nil then
        buttons[title] = {
            clicked = false,
            size = 80
        }
    end
    UiPush()
    UiColor(1, 1, 1)
    UiAlign("right middle")
    UiFont("regular.ttf", 24)
    UiText(title)
    UiTranslate(0, 42)
    if UiIsMouseInRect(80, 40) then
        UiColor(0.9, 0.9, 0.9)
        if InputDown("lmb") then
            buttons[title].clicked = true
            UiColor(0.8, 0.8, 0.8)
            buttons[title].size = 76
            UiTranslate(-2, 0)
        else
            buttons[title].size = 80
        end
        if buttons[title].clicked and not InputDown("lmb") then
            PlaySound(clicksnd)
            value = not value
            buttons[title].clicked = false
        end
    else
        UiColor(1, 1, 1)
        buttons[title].clicked = false
        buttons[title].size = 80
    end

    if value then
        UiImageBox("MOD/images/buttonon.png", buttons[title].size, buttons[title].size/2)
    else
        UiImageBox("MOD/images/buttonoff.png", buttons[title].size, buttons[title].size/2)
    end
    UiPop()
    return value
end