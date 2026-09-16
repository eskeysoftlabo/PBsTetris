dofile('PBsTetris/Audio.lua')
local clock,played,current=10,{},17
GetFrameTimeSeconds=function() return clock end
SOUNDS={DEFAULT_CLICK='click',LOCKPICKING_CHAMBER_START='rotate',LOCKPICKING_CHAMBER_LOCKED='lock',SCRYING_CAPTURE_HEX_LARGE='clear'}
PlaySound=function(id) played[#played+1]=id end
GetOverrideMusicMode=function() return current end
SetOverrideMusicMode=function(mode) current=mode end
OVERRIDE_MUSIC_MODE_TRIBUTE,OVERRIDE_MUSIC_MODE_CHAMPION,OVERRIDE_MUSIC_MODE_DUELING,OVERRIDE_MUSIC_MODE_CREDITS=3,4,5,6
local saved={soundEnabled=true};local audio=PBT.Audio.New(saved)
audio:Sync(true);assert(current==3,'default mode is Tribute');audio:Sync(true);audio:Stop();assert(current==17)
audio:Sync(true);current=99;audio:Stop();assert(current==99,'must not overwrite another addon or game override')
saved.musicMode='off';audio:Sync(true);assert(current==99)
saved.musicMode='champion';audio:Sync(true);assert(current==4,'selected mode applies');audio:Sync(true);assert(current==4)
saved.musicMode='dueling';audio:Sync(true);assert(current==5,'switching mode keeps ownership');audio:Stop();assert(current==99,'restores the mode owned before the addon started')
assert(audio:Cycle(true)=='BGM：終幕' and current==6,'cycle advances and applies')
assert(audio:Cycle(true)=='BGM：切' and saved.musicMode=='off' and current==99,'cycle wraps to off and restores')
assert(audio:Cycle(true)=='BGM：カード' and current==3)
saved.musicMode='champion';current=42;audio:Sync(true);assert(current==42,'yields when another override took over mid-game')
audio:Sync(true);assert(current==42,'stays yielded instead of fighting')
audio:Stop();audio:Sync(true);assert(current==4,'a fresh session takes the override again')
saved.musicMode='nonsense';audio:Sync(true);assert(current==3,'unknown saved mode falls back to the default')
audio:Sync(false);assert(current==42,'leaving play restores the override from before the game started')
audio:Play('move');audio:Play('move');assert(#played==1);clock=11;audio:Play('move');assert(#played==2)
saved.soundEnabled=false;audio:Play('rotate');assert(#played==2)
saved.soundEnabled=true;local e=PBT.Engine.New(2);audio:Bind(e);e:Drop();assert(played[#played]=='lock')
local last=#played;e.over=true;e:Move(1);assert(#played==last)
SOUNDS={};clock=12;audio:Play('rotate');assert(#played==last,'unknown built-in sound should be ignored')
print('PASS audio: music modes, cycling, restoration, ownership, toggles, throttling, engine events, unknown IDs')
