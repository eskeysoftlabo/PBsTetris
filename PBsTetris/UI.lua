PBT=PBT or {}
local U={};U.__index=U;PBT.UI=U
-- 1-8 are the pieces and garbage. 9 and 10 are a row on its way out: white for an ordinary
-- clear, gold for four at once, which is the only place either colour is used.
local colors={{.35,.82,.87},{.94,.8,.35},{.72,.45,.85},{.38,.55,.94},{.94,.57,.3},{.45,.8,.46},{.88,.38,.39},{.52,.53,.55},{1,.97,.9},{1,.84,.35}}
local WIPE,QUAD_WIPE=.18,.3
local FLAKES=48
-- The highlight crosses the board diagonally over SHINE seconds and then stays away for the
-- rest of SHINE_CYCLE, so it reads as an occasional glint rather than a strobe.
local SHINE,SHINE_CYCLE,SHINE_WIDTH=1.5,4.2,.16
local function box(parent,x,y,w,h)
 local c=WINDOW_MANAGER:CreateControl(nil,parent,CT_BACKDROP);c:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);c:SetDimensions(w,h)
 c:SetCenterColor(.018,.022,.026,.97);c:SetEdgeColor(.48,.4,.26,1);c:SetEdgeTexture('',1,1,1);return c
end
local function text(parent,x,y,w,h,size,value)
 local c=WINDOW_MANAGER:CreateControl(nil,parent,CT_LABEL);c:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);c:SetDimensions(w,h)
 c:SetFont('ZoFontGamepad'..size);c:SetHorizontalAlignment(TEXT_ALIGN_CENTER);c:SetColor(.9,.86,.74,1);c:SetDrawLayer(DL_TEXT);c:SetText(value or '');return c
end
local function tile(parent,x,y,size)
 local c=WINDOW_MANAGER:CreateControl(nil,parent,CT_TEXTURE);c:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);c:SetDimensions(size-2,size-2)
 c:SetTexture('PBsTetris/assets/stone.dds');c:SetDrawLayer(DL_CONTROLS);return c
end
-- shine is 0-4, a quantised distance from the highlight sweeping over the stack. Quantising
-- it is what keeps this cheap: a cell is recoloured when it changes step, not every frame.
local function paint(c,v,shine)
 shine=shine or 0
 if c.value==v and c.shine==shine then return end
 c.value=v;c.shine=shine;c:SetHidden(v==0)
 if v~=0 then
  local rgb=colors[math.abs(v)];local lift=v<0 and 0 or shine*.17
  c:SetColor(rgb[1]+(1-rgb[1])*lift,rgb[2]+(1-rgb[2])*lift,rgb[3]+(1-rgb[3])*lift,v<0 and .23 or 1)
 end
end
function U.New(app)
 local self=setmetatable({app=app,cells={},minis={},flakes={},snowAt=0},U)
 local root=WINDOW_MANAGER:CreateTopLevelWindow('PBsTetrisWindow');self.root=root
 root:SetAnchorFill(GuiRoot);root:SetHidden(true)
 local sky=WINDOW_MANAGER:CreateControl(nil,root,CT_TEXTURE);sky:SetAnchorFill(root);sky:SetTexture('PBsTetris/assets/sanctuary.dds');sky:SetDrawLayer(DL_BACKGROUND);sky:SetDrawLevel(0);self.sky=sky
 local veil=box(root,0,0,1,1);veil:SetAnchorFill(root);veil:SetCenterColor(.012,.025,.045,.24);veil:SetEdgeColor(0,0,0,0);veil:SetDrawLayer(DL_BACKGROUND);veil:SetDrawLevel(1)
 local content=WINDOW_MANAGER:CreateControl(nil,root,CT_CONTROL);content:SetDimensions(1100,850);content:SetAnchor(CENTER,root,CENTER,0,-20);self.content=content;root=content
 local stone=tile(root,0,0,1102);stone:SetDimensions(1100,850);stone:SetDrawLayer(DL_BACKGROUND);stone:SetColor(.22,.29,.34,.88)
 text(root,0,30,1100,30,22,'ゲームセンターPX')
 text(root,0,63,1100,55,42,'タムリエル de テトリス'):SetColor(.91,.77,.48,1)
 self.mode=text(root,0,118,1100,35,22)
 box(root,390,162,320,620)
 for y=1,20 do self.cells[y]={};for x=1,10 do self.cells[y][x]=tile(root,400+(x-1)*30,172+(y-1)*30,30) end end
 text(root,65,173,270,35,27,'ホールド');self:Mini(65,220)
 text(root,765,173,270,35,27,'次のブロック')
 for i=1,3 do self:Mini(765,220+(i-1)*112) end
 self.stats=text(root,65,390,270,260,27)
 self.record=text(root,65,670,270,75,22)
 self.enemy=text(root,755,575,290,160,22)
 self.footer=text(root,45,800,1010,28,18,'方向キー：移動　下：速く落とす　上：一気に落とす　L1：左回転')
 self.overlay=box(root,402,365,296,200);self.overlay:SetDrawLayer(DL_OVERLAY)
 self.message=text(self.overlay,8,15,280,170,27);self.message:SetDrawLayer(DL_OVERLAY);self.message:SetDrawLevel(1)
 for i=1,FLAKES do
  local c=WINDOW_MANAGER:CreateControl(nil,self.root,CT_TEXTURE)
  c:SetTexture('PBsTetris/assets/flake.dds');c:SetDrawLayer(DL_OVERLAY);c:SetDrawLevel(2);c:SetHidden(true)
  self.flakes[i]={control=c}
 end
 self.keybinds={alignment=KEYBIND_STRIP_ALIGN_CENTER}
 for _,entry in ipairs({{'UI_SHORTCUT_PRIMARY','primary'},{'UI_SHORTCUT_SECONDARY','drop'},{'UI_SHORTCUT_TERTIARY','hold'},{'UI_SHORTCUT_NEGATIVE','back'},{'UI_SHORTCUT_LEFT_SHOULDER','ccw'},{'UI_SHORTCUT_RIGHT_SHOULDER','music'}}) do
  local action=entry[2]
  self.keybinds[#self.keybinds+1]={keybind=entry[1],name=function() return app:ActionName(action) end,callback=function() app:Action(action) end}
 end
 self.scene=ZO_Scene:New('pbtGame',SCENE_MANAGER)
 self.scene:AddFragment(ZO_SimpleSceneFragment:New(self.root));self.scene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
 self.scene:AddFragment(ZO_ActionLayerFragment:New('PBsTetrisInput'))
 self.scene:RegisterCallback('StateChange',function(_,state)
  if state==SCENE_SHOWING then
   self.content:SetScale(math.min((GuiRoot:GetHeight()-100)/850,(GuiRoot:GetWidth()-80)/1100));self:Refresh();KEYBIND_STRIP:AddKeybindButtonGroup(self.keybinds)
  elseif state==SCENE_HIDING then KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybinds);app:Hidden() end
 end)
 return self
end
function U:Mini(x,y)
 local cells={};for i=1,16 do cells[i]=tile(self.content,x+75+((i-1)%4)*27,y+math.floor((i-1)/4)*27,27) end
 self.minis[#self.minis+1]=cells
end
function U:DrawMini(index,name)
 local values={};if name then for _,p in ipairs(PBT.Engine.Cells(name,0,0,0)) do values[p[2]*4+p[1]+1]=PBT.Engine.ids[name] end end
 for i,c in ipairs(self.minis[index]) do paint(c,values[i] or 0) end
end
-- Holds the board as it stood when the rows filled up, until the wipe has swept across it.
-- Returns how far the sweep has got, or nil once the live board should be drawn again.
function U:Wipe(e)
 local wipe=e and e.wipe
 if wipe~=self.wipe then self.wipe=wipe;self.wipeAt=wipe and GetFrameTimeSeconds() end
 if not wipe then return nil end
 local progress=(GetFrameTimeSeconds()-self.wipeAt)/(wipe.quad and QUAD_WIPE or WIPE)
 if progress<0 or progress>=1 then return nil end
 return wipe,math.floor(progress*10),wipe.quad and 10 or 9
end
-- Snow answers to how much room is left: a few flakes over a clear board, a blizzard once the
-- stack is at the ceiling. Falling is done here rather than with animation timelines because
-- the count changes every few seconds and rebuilding timelines would cost more than moving a
-- texture does.
local function reseed(f,width,height,top)
 f.x=math.random()*width;f.y=top and -math.random()*height*.4 or math.random()*height
 f.fall=height*(.05+math.random()*.09);f.sway=8+math.random()*26;f.phase=math.random()*6.28
 f.size=3+math.random()*7
 f.control:SetDimensions(f.size,f.size)
 f.control:SetColor(1,1,1,.25+math.random()*.35)
end
function U:Snow(e,now)
 local dt=math.min(.1,math.max(0,now-self.snowAt));self.snowAt=now
 local height=e and e:Height() or 0
 local weight=math.min(1,height/18)
 local wanted=e and math.floor(FLAKES*(.06+.94*weight*weight)) or 0
 local width,tall=self.root:GetWidth(),self.root:GetHeight()
 for i,f in ipairs(self.flakes) do
  if i>wanted then
   if f.y then f.y=nil;f.control:SetHidden(true) end
  else
   if not f.y then reseed(f,width,tall,false);f.control:SetHidden(false) end
   f.y=f.y+f.fall*dt*(.7+weight)
   if f.y>tall then reseed(f,width,tall,true) end
   f.control:SetAnchor(TOPLEFT,self.root,TOPLEFT,f.x+math.sin(now*1.7+f.phase)*f.sway,f.y)
  end
 end
end
function U:Shine(now)
 local at=now%SHINE_CYCLE
 if at>SHINE then return nil end
 return -.3+(at/SHINE)*1.6
end
function U:Refresh()
 local app=self.app;local e=app:Engine();local m=app.match
 self.mode:SetText(app.solo and (e and e:Is20G() and 'ひとりで挑戦 · 20G' or 'ひとりで挑戦 · スコアアタック') or ('対戦相手：'..(m.peer or '未選択')))
 local now=GetFrameTimeSeconds()
 local wipe,swept,tint=self:Wipe(e);self.wiping=wipe~=nil
 local board=wipe and wipe.board or (e and e:View())
 local glint=not wipe and self:Shine(now) or nil
 for y=1,20 do for x=1,10 do
  local value=board and board[y+2][x] or 0
  local shine=0
  if wipe and wipe.clearing[y+2] then value=x<=swept and 0 or tint
  elseif glint and value>0 then
   local along=((x-1)/9+(20-y)/19)/2
   shine=math.floor(math.max(0,1-math.abs(along-glint)/SHINE_WIDTH)*4+.5)
  end
  paint(self.cells[y][x],value,shine)
 end end
 self:Snow(e,now)
 self:DrawMini(1,e and e.hold)
 for i=1,3 do self:DrawMini(i+1,e and e.queue[i]) end
 self.stats:SetText(string.format('スコア\n%d\n\n消したライン　%d\nレベル　%d',e and e.score or 0,e and e.lines or 0,e and e.level or 1))
 self.record:SetText((e and e.force20G and '20G 自己ベスト\n' or '自己ベスト\n')..(e and e.force20G and (app.saved.highScore20G or 0) or app.saved.highScore))
 self.enemy:SetText(app.solo and (e and e:Is20G() and '20G · 即時接地\n地面を滑らせて配置\n固定猶予 0.5秒' or '10ラインごとに速度上昇\nレベル20から20G') or string.format('相手の高さ　%d / 22\n受けるおじゃま　%d 段\n送ったおじゃま　%d 段',m.peerHeight or 0,e and e.pending or 0,e and e.sent or 0))
 local status=''
 if app.solo then
  if e.over then status='挑戦終了\n\nスコア　'..e.score..'\nもう一度挑戦できます'
  elseif e.paused then status='一時停止\n\n再開して冒険の続きを' end
 else
  local labels={inviting='招待を送りました\n\n相手の返答を待っています',invited='対戦に招待されました\n\n承諾すると開始します',accepted='開始を準備しています',result=m.result,aborted=m.reason,idle='対人メニューから\n相手を招待してください'}
  status=labels[m.state] or ''
  if m.state=='countdown' then status='まもなく対戦開始\n\n'..math.max(0,m.startAt-GetTimeStamp()) end
 end
 self.overlay:SetHidden(status=='');self.message:SetText(status)
 if self.scene:IsShowing() then KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybinds) end
end
