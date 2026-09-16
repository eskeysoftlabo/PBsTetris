PBT=PBT or {}
local Audio={};Audio.__index=Audio;PBT.Audio=Audio
local ids={move='DEFAULT_CLICK',rotate='LOCKPICKING_CHAMBER_START',hold='ENCHANTING_POTENCY_RUNE_PLACED',lock='LOCKPICKING_CHAMBER_LOCKED',clear='SCRYING_CAPTURE_HEX_LARGE',quad='SCRYING_CAPTURE_GOAL',start='DUEL_START',win='DUEL_WON',lose='DUEL_FORFEIT'}
local modes={{key='off',label='BGM：切'},{key='tribute',label='BGM：カード',global='OVERRIDE_MUSIC_MODE_TRIBUTE'},{key='champion',label='BGM：星座',global='OVERRIDE_MUSIC_MODE_CHAMPION'},{key='dueling',label='BGM：決闘',global='OVERRIDE_MUSIC_MODE_DUELING'},{key='credits',label='BGM：終幕',global='OVERRIDE_MUSIC_MODE_CREDITS'}}
local order={};for i,mode in ipairs(modes) do order[mode.key]=i end
Audio.Modes=modes
function Audio.New(saved) return setmetatable({saved=saved,last={}},Audio) end
function Audio:Index() return order[self.saved.musicMode] or order.tribute end
function Audio:Label() return modes[self:Index()].label end
function Audio:Cycle(active)
 self.saved.musicMode=modes[self:Index()%#modes+1].key;self.yielded=nil;self:Sync(active);return self:Label()
end
function Audio:Play(kind)
 if self.saved.soundEnabled==false then return end
 local now=GetFrameTimeSeconds();if now-(self.last[kind] or -100)<(kind=='move' and .09 or .045) then return end
 self.last[kind]=now
 local id=SOUNDS and SOUNDS[ids[kind]]
 if id and PlaySound then PlaySound(id) end
end
function Audio:Bind(engine)
 if engine then engine.onEvent=function(kind) self:Play(kind) end end
end
function Audio:Sync(active)
 local name=active and modes[self:Index()].global
 local want=name and rawget(_G,name)
 if not want then self:Stop();return end
 if not (GetOverrideMusicMode and SetOverrideMusicMode) then return end
 if self.owned then
  if self.mode==want then return end
  if GetOverrideMusicMode()~=self.mode then self.owned=false;self.previous=nil;self.yielded=true;return end
  if pcall(SetOverrideMusicMode,want) then self.mode=want end
  return
 end
 if self.yielded then return end
 local previous=GetOverrideMusicMode()
 if pcall(SetOverrideMusicMode,want) then self.owned=true;self.previous=previous;self.mode=want end
end
function Audio:Stop()
 if self.owned then
  if GetOverrideMusicMode and GetOverrideMusicMode()==self.mode then pcall(SetOverrideMusicMode,self.previous) end
  self.owned=false;self.previous=nil
 end
 self.yielded=nil
end
