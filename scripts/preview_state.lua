-- Use the actual engine's cell geometry and board projection for the visual preview.
dofile('PBsTetris/Engine.lua')
local e=PBT.Engine.New(42,false)
local rows={
 {0,0,0,0,0,0,0,0,0,0},
 {0,0,0,0,0,0,0,0,2,2},
 {0,0,0,0,0,0,6,6,2,2},
 {0,0,0,0,0,6,6,4,4,4},
 {3,0,0,0,0,5,5,5,7,7},
 {3,3,0,0,0,5,1,1,1,1},
 {3,2,2,0,6,6,4,4,7,7},
 {4,2,2,0,6,1,1,1,1,7},
}
for i,row in ipairs(rows) do e.board[14+i]=row end
e.piece='T';e.rotation=0;e.x=4;e.y=7;e.hold='I';e.queue={'O','L','S'}
local function json(v)
 if type(v)=='table' then local t={};for _,x in ipairs(v) do t[#t+1]=json(x) end;return '['..table.concat(t,',')..']' end
 if type(v)=='string' then return '"'..v..'"' end
 return tostring(v)
end
local shapes={};for _,name in ipairs({'I','O','L','S'}) do shapes[#shapes+1]={PBT.Engine.ids[name],PBT.Engine.Cells(name,0,0,0)} end
print('window.PREVIEW_STATE={board:'..json(e:View())..',minis:'..json(shapes)..'};')
-- A repeatable recording of the real Lua 20G engine, not a separate JS physics implementation.
local g=PBT.Engine.New(42,false,true);g.board[18][5]=8;g:Spawn('O')
local frames={}
for frame=0,149 do
 if frame==8 or frame==15 then g:Move(1) end
 if frame==46 then g:Rotate(1) end
 if frame==64 then g:Hold() end
 if frame==85 or frame==91 then g:Move(-1) end
 local minis={}
 for i=1,4 do
  local name=i==1 and g.hold or g.queue[i-1]
  if name then minis[i]={PBT.Engine.ids[name],PBT.Engine.Cells(name,0,0,0)} else minis[i]={0,{}} end
 end
 frames[#frames+1]={g:View(),g.lock,minis,g.score}
 g:Tick(.02)
end
print('window.PREVIEW_20G='..json(frames)..';')
