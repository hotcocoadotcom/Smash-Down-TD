function init()
    waves = LoadLoop("MOD/music/menu/waves.ogg")
    lead = LoadLoop("MOD/music/menu/lead.ogg")
    drums = LoadLoop("MOD/music/menu/drums.ogg")
end

function tick(dt)
    if InputDown("b") then
        PlayLoop(waves, GetPlayerPos(), 1, true, 1.5)
    end
    if InputDown("n") then
        PlayLoop(lead, GetPlayerPos(), 1, true, 1.5)
    end
    if InputDown("m") then
        PlayLoop(drums, GetPlayerPos(), 1, true, 1.5)
    end
    SetSoundLoopProgress(lead, GetSoundLoopProgress(waves))
    SetSoundLoopProgress(drums, GetSoundLoopProgress(waves))
    DebugWatch("progress",GetSoundLoopProgress(waves))
end