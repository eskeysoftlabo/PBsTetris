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
 scene={shown=false,fragments={},AddFragment=function(self,f) self.fragments[#self.fragments+1]=f end,AddFragmentGroup=function() end,RegisterCallback=function(self,_,f) self.callback=f end,IsShowing=function(self) return self.shown end};return scene
end}
-- A simple scene fragment shows and hides the control it was built from, which is the whole
-- reason the game window appears at all. The double does the same, so that handing the
-- fragment the wrong control fails here rather than in front of a player.
local function setHidden(hidden) for _,f in ipairs(scene.fragments) do if f.control then f.control:SetHidden(hidden) end end end
SCENE_MANAGER={Show=function() if not scene.shown then scene.shown=true;setHidden(false);scene.callback(nil,SCENE_SHOWING) end end,Hide=function() if scene.shown then scene.shown=false;setHidden(true);scene.callback(nil,SCENE_HIDING) end end}
ZO_SimpleSceneFragment={New=function(_,control) return {control=control} end};ZO_ActionLayerFragment={New=function() return {} end};FRAGMENT_GROUP={GAMEPAD_DRIVEN_UI_WINDOW={}}
ZO_SavedVars={NewAccountWide=function() return {highScore=0,bestLines=0} end}
local clock=100;GetFrameTimeSeconds=function() return clock end;GetTimeStamp=function() return 100000 end;GetDisplayName=function() return '@self' end
ZO_PreHook=function() end;ZO_Alert=function() end;SLASH_COMMANDS={}
EVENT_MANAGER={RegisterForEvent=function() end,UnregisterForEvent=function() end,RegisterForUpdate=function() end}
PBT.Transport={New=function() return {Allowed=function() return true end,Send=function() return true end} end}
PBT.HookMenus=function() end
for _,name in ipairs({'Audio','UI','Main'}) do dofile('PBsTetris/'..name..'.lua') end
local a=PBT.App;a:Initialize();a.match:Tick(0)
assert(a.ui.root.hidden,'the window starts hidden')
a:Solo()
assert(a.ui.root.hidden==false,'the top level window must be what the scene shows, not a child of it')
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

a:Solo(true)
local e=a.soloEngine
for y=19,22 do for x=1,10 do e.board[y][x]=x==5 and 0 or 8 end end
e.piece='I';e.rotation=1;e.x=3;e.y=19;e:Drop()
local bottom=a.ui.cells[20]
a.ui:Refresh();assert(a.ui.wiping and bottom[1].value==10,'four at once wipes in its own colour')
clock=clock+.16;a.ui:Refresh();assert(bottom[1].value==0 and bottom[6].value==10,'the row is swept away from the left')
clock=clock+.2;a.ui:Refresh();assert(not a.ui.wiping and bottom[1].value==0,'the live board comes back once the sweep is over')
a:Solo(true);e=a.soloEngine;clock=clock+1
for x=1,10 do e.board[22][x]=x==5 and 0 or 8 end
e.piece='I';e.rotation=1;e.x=3;e.y=19;e:Drop()
a.ui:Refresh();assert(a.ui.cells[20][1].value==9,'an ordinary clear wipes white, not gold')
print('PASS line clear wipe: colours, sweep direction, and handing the board back')

local function falling() local n=0;for _,f in ipairs(a.ui.flakes) do if not f.control.hidden then n=n+1 end end;return n end
a:Solo(true);e=a.soloEngine;clock=clock+1;a.ui:Refresh()
local calm=falling();assert(calm>0,'a clear board still gets a little snow')
for y=6,22 do for x=1,10 do e.board[y][x]=8 end end
clock=clock+1;a.ui:Refresh()
local heavy=falling();assert(heavy>calm*3,'a stack near the ceiling snows far harder: '..calm..' -> '..heavy)
local moved=false
for _,f in ipairs(a.ui.flakes) do local y=f.y;clock=clock+.05;a.ui:Refresh();if f.y and y and f.y~=y then moved=true end end
assert(moved,'the flakes actually fall')
for y=6,22 do for x=1,10 do e.board[y][x]=0 end end
clock=clock+1;a.ui:Refresh();assert(falling()<heavy,'clearing the stack calls the snow off again')

for x=1,9 do e.board[22][x]=8 end
local lit,plain=false,false
for _=1,60 do
 clock=clock+.06;a.ui:Refresh()
 for x=1,10 do local shine=a.ui.cells[20][x].shine;if shine and shine>0 then lit=true elseif shine==0 then plain=true end end
end
assert(lit and plain,'the stack catches a highlight that passes, rather than staying lit')
print('PASS snow and shine: intensity follows the stack, flakes fall, the glint passes over')