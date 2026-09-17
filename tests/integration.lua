-- Runtime wiring smoke test with explicit ESO API doubles (not an ESO emulator).
local function control()
 local c={}
 for _,name in ipairs({'SetAnchorFill','SetCenterColor','SetEdgeColor','SetEdgeTexture','SetFont','SetHorizontalAlignment','SetColor','SetDrawLayer','SetDrawLevel','SetDrawTier','SetTexture','SetScale'}) do c[name]=function() end end
 c.SetAlpha=function(self,v) self.alpha=v end
 c.SetAnchor=function(self,_,_,_,x,y) self.x,self.y=x,y end
 c.SetDimensions=function(self,w,h) self.w,self.h=w,h end
 c.SetHidden=function(self,v) self.hidden=v end;c.SetText=function(self,v) self.text=v end
 c.GetHeight=function() return 1080 end;c.GetWidth=function() return 1920 end
 return c
end
WINDOW_MANAGER={CreateControl=function() return control() end,CreateTopLevelWindow=function() return control() end};GuiRoot=control()
KEYBIND_STRIP={AddKeybindButtonGroup=function() end,RemoveKeybindButtonGroup=function() end,UpdateKeybindButtonGroup=function() end}
SCENE_SHOWING='showing';SCENE_SHOWN='shown';SCENE_HIDING='hiding';local scene
ZO_Scene={New=function()
 scene={shown=false,fragments={},AddFragment=function(self,f) self.fragments[#self.fragments+1]=f end,AddFragmentGroup=function() end,RegisterCallback=function(self,_,f) self.callback=f end,IsShowing=function(self) return self.shown end};return scene
end}
-- A simple scene fragment shows and hides the control it was built from, which is the whole
-- reason the game window appears at all. The double does the same, so that handing the
-- fragment the wrong control fails here rather than in front of a player.
local function setHidden(hidden) for _,f in ipairs(scene.fragments) do if f.control then f.control:SetHidden(hidden) end end end
-- Show only starts the transition. The scene reports itself SHOWN once the frames it takes
-- have passed, which is what Settle stands in for.
SCENE_MANAGER={Show=function() if not scene.shown then scene.shown=true;setHidden(false);scene.callback(nil,SCENE_SHOWING) end end,
 Settle=function() if scene.shown then scene.callback(nil,SCENE_SHOWN) end end,Hide=function() if scene.shown then scene.shown=false;setHidden(true);scene.callback(nil,SCENE_HIDING) end end}
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
-- Opening the board goes through the fade, so the tests have to let the curtain fall and lift
-- exactly as the game's own update loop does.
local function reveal() for i=1,16 do a.ui:Tick(.1);if i==4 then SCENE_MANAGER.Settle() end end end
a:Solo()
assert(a.ui.root.hidden and not a.ui.curtain.hidden,'the world goes dark before the board is shown')
for _=1,3 do a.ui:Tick(.1) end
assert(a.ui.curtain.alpha==1 and not a.ui.root.hidden,'the board appears at full black')
for _=1,6 do a.ui:Tick(.1) end
assert(a.ui.curtain.alpha==1,'the curtain waits for the scene rather than the clock')
SCENE_MANAGER.Settle()
for _=1,6 do a.ui:Tick(.1) end
assert(a.ui.curtain.hidden,'and lifts once the board reports itself shown')
assert(a.ui.root.hidden==false,'the top level window must be what the scene shows, not a child of it')
assert(a:Playable());local x=a:Engine().x;a:Input('left',true);assert(a:Engine().x==x-1)
a:Action('back');assert(a:Engine().paused);a:Action('primary');assert(not a:Engine().paused)
a:Action('back');a:Action('back');assert(not scene.shown);assert(not a.keys.left)
a:Solo();reveal();assert(a:Playable());a.soloEngine.over=true;a:Action('primary');assert(not a.soloEngine.over)
a:Challenge('@other');reveal();assert(a.match.state=='inviting');SCENE_MANAGER:Hide('pbtGame');assert(a.match.state=='aborted')
a.match:Reset('@other',333,42,true,'playing');a.match.engine=PBT.Engine.New(42,true);SCENE_MANAGER:Show('pbtGame');a:Action('back');assert(a.match.terminal==2)
print('PASS runtime wiring: solo, pause, resume, restart, input cleanup, challenge cancellation and surrender')
a:Solo(false,true);reveal();assert(a.soloEngine.force20G and a.soloEngine:Grounded());a.soloEngine.score=123;a:Save();assert(a.saved.highScore20G==123)
a.soloEngine.over=true;a:Action('primary');assert(a.soloEngine.force20G and a.soloEngine:Grounded())
a:Solo(false,false);assert(not a.soloEngine.force20G and not a.soloEngine:Grounded())
print('PASS 20G runtime: direct launch, separate record, retry preserves mode, normal mode restore')

a:Solo(true);reveal()
local e=a.soloEngine
for y=19,22 do for x=1,10 do e.board[y][x]=x==5 and 0 or 8 end end
e.piece='I';e.rotation=1;e.x=3;e.y=19;e:Drop()
local bottom=a.ui.cells[20]
a.ui:Refresh();assert(a.ui.wiping and bottom[1].value==10,'four at once wipes in its own colour')
clock=clock+.16;a.ui:Refresh();assert(bottom[1].value==0 and bottom[6].value==10,'the row is swept away from the left')
clock=clock+.2;a.ui:Refresh();assert(not a.ui.wiping and bottom[1].value==0,'the live board comes back once the sweep is over')
a:Solo(true);reveal();e=a.soloEngine;clock=clock+1
for x=1,10 do e.board[22][x]=x==5 and 0 or 8 end
e.piece='I';e.rotation=1;e.x=3;e.y=19;e:Drop()
a.ui:Refresh();assert(a.ui.cells[20][1].value==9,'an ordinary clear wipes white, not gold')
print('PASS line clear wipe: colours, sweep direction, and handing the board back')

local function falling() local n=0;for _,f in ipairs(a.ui.flakes) do if not f.control.hidden then n=n+1 end end;return n end
a:Solo(true);reveal();e=a.soloEngine;clock=clock+1;a.ui:Refresh()
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

SCENE_MANAGER:Hide('pbtGame');a:Solo();a.ui:CancelFade();reveal()
assert(a.ui.curtain.hidden and not scene.shown,'a cancelled fade lifts without ever showing the board')
a:Solo(true);reveal();e=a.soloEngine;clock=clock+1
a.ui:Refresh();assert(a.ui.banner.hidden,'a new game does not announce level 1')
e.level=2;clock=clock+.1;a.ui:Refresh()
assert(not a.ui.banner.hidden and a.ui.banner.text=='レベル 2','a level up is announced')
clock=clock+2;a.ui:Refresh();assert(a.ui.banner.hidden,'and the announcement goes away on its own')
e.level=20;clock=clock+.1;a.ui:Refresh();assert(a.ui.banner.text=='レベル 20 · 20G','reaching 20G says so')
a:Solo(true);reveal();clock=clock+3;a.ui:Refresh()
assert(a.ui.banner.hidden,'starting over does not announce anything')
print('PASS level up: announced once, on the board that earned it, and it clears itself')

a.ui:Fade(function() end)
for _=1,20 do a.ui:Tick(.1) end
assert(a.ui.curtain.hidden,'a scene that never reports itself shown cannot leave the screen black')
print('PASS fade: the screen darkens before the board, waits for it, and combat can call it off')

-- Duel layout: the player's own half on the left, the opponent's on the right.
a:Solo(true);reveal();a.ui:Refresh()
local soloBoard=a.ui.cells[1][1].x
assert(a.ui.record.hidden==false and a.ui.gaugeFrame.hidden,'solo keeps its record and has no opponent half')
a.solo=false;a.match:Reset('@other',7,42,true,'playing');a.match.engine=PBT.Engine.New(42,true)
a.match.peerHeight=11;a.ui:Refresh()
assert(a.ui.cells[1][1].x<soloBoard,'the board moves off centre for a duel')
for y=1,20 do for x=1,10 do assert(a.ui.cells[y][x].x+30<=550,'every cell of the board is in the left half') end end
for _,index in ipairs({1,2,3,4}) do
 for _,c in ipairs(a.ui.minis[index]) do assert(c.x+27<=550,'the hold and next panels are in the left half too') end
end
assert(a.ui.gaugeFrame.hidden==false and a.ui.peerLabel.hidden==false,'the opponent gets the right half')
assert(a.ui.gauge.hidden==false and a.ui.gauge.h==math.floor(600*11/22),'the gauge stands at the height that was reported')
assert(a.ui.gauge.x>=550,'and it stands on the right')
a.match.peerHeight=0;a.ui:Refresh();assert(a.ui.gauge.hidden,'an empty board has nothing to show')
a.solo=true;a.ui:Refresh()
assert(a.ui.cells[1][1].x==soloBoard and a.ui.gaugeFrame.hidden,'going back to solo puts the board back')
print('PASS duel layout: own half on the left, opponent half on the right, restored for solo')