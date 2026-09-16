-- Runtime wiring smoke test with explicit ESO API doubles (not an ESO emulator).
local function control()
 local c={}
 for _,name in ipairs({'SetAnchor','SetAnchorFill','SetDimensions','SetCenterColor','SetEdgeColor','SetEdgeTexture','SetFont','SetHorizontalAlignment','SetColor','SetDrawLayer','SetDrawLevel','SetTexture','SetScale'}) do c[name]=function() end end
 c.SetHidden=function(self,v) self.hidden=v end;c.SetText=function(self,v) self.text=v end
 c.GetHeight=function() return 1080 end;c.GetWidth=function() return 1920 end
 return c
end
WINDOW_MANAGER={CreateControl=function() return control() end,CreateTopLevelWindow=function() return control() end};GuiRoot=control()
KEYBIND_STRIP={AddKeybindButtonGroup=function() end,RemoveKeybindButtonGroup=function() end,UpdateKeybindButtonGroup=function() end}
SCENE_SHOWING='showing';SCENE_HIDING='hiding';local scene
ZO_Scene={New=function()
 scene={shown=false,AddFragment=function() end,AddFragmentGroup=function() end,RegisterCallback=function(self,_,f) self.callback=f end,IsShowing=function(self) return self.shown end};return scene
end}
SCENE_MANAGER={Show=function() if not scene.shown then scene.shown=true;scene.callback(nil,SCENE_SHOWING) end end,Hide=function() if scene.shown then scene.shown=false;scene.callback(nil,SCENE_HIDING) end end}
ZO_SimpleSceneFragment={New=function() return {} end};ZO_ActionLayerFragment={New=function() return {} end};FRAGMENT_GROUP={GAMEPAD_DRIVEN_UI_WINDOW={}}
ZO_SavedVars={NewAccountWide=function() return {highScore=0,bestLines=0} end}
GetFrameTimeSeconds=function() return 100 end;GetTimeStamp=function() return 100000 end;GetDisplayName=function() return '@self' end
ZO_PreHook=function() end;ZO_Alert=function() end;SLASH_COMMANDS={}
EVENT_MANAGER={RegisterForEvent=function() end,UnregisterForEvent=function() end,RegisterForUpdate=function() end}
PBT.Transport={New=function() return {Allowed=function() return true end,Send=function() return true end} end}
PBT.HookMenus=function() end
for _,name in ipairs({'Audio','UI','Main'}) do dofile('PBsTetris/'..name..'.lua') end
local a=PBT.App;a:Initialize();a.match:Tick(0);a:Solo()
assert(a:Playable());local x=a:Engine().x;a:Input('left',true);assert(a:Engine().x==x-1)
a:Action('back');assert(a:Engine().paused);a:Action('primary');assert(not a:Engine().paused)
a:Action('back');a:Action('back');assert(not scene.shown);assert(not a.keys.left)
a:Solo();assert(a:Playable());a.soloEngine.over=true;a:Action('primary');assert(not a.soloEngine.over)
a:Challenge('@other');assert(a.match.state=='inviting');SCENE_MANAGER:Hide('pbtGame');assert(a.match.state=='aborted')
a.match:Reset('@other',333,42,true,'playing');a.match.engine=PBT.Engine.New(42,true);SCENE_MANAGER:Show('pbtGame');a:Action('back');assert(a.match.terminal==2)
print('PASS runtime wiring: solo, pause, resume, restart, input cleanup, challenge cancellation and surrender')
a:Solo(false,true);assert(a.soloEngine.force20G and a.soloEngine:Grounded());a.soloEngine.score=123;a:Save();assert(a.saved.highScore20G==123)
a.soloEngine.over=true;a:Action('primary');assert(a.soloEngine.force20G and a.soloEngine:Grounded())
a:Solo(false,false);assert(not a.soloEngine.force20G and not a.soloEngine:Grounded())
print('PASS 20G runtime: direct launch, separate record, retry preserves mode, normal mode restore')
