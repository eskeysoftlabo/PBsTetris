-- Pure Lua tests. Run from the project root with Lua 5.1+.
unpack=unpack or table.unpack
for _,file in ipairs({'SHA256','Engine','Match'}) do dofile('PBsTetris/'..file..'.lua') end
local count=0
local function test(name,f) local ok,err=pcall(f);if not ok then error(name..': '..tostring(err)) end;count=count+1;print('PASS '..name) end
local E=PBT.Engine
local function equal(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function setupClear(n,pending)
 local e=E.New(42,true)
 for y=23-n,22 do for x=1,10 do e.board[y][x]=x==5 and 0 or 8 end end
 e.piece='I';e.rotation=1;e.x=3;e.y=19;e.pending=pending or 0;return e
end
test('SHA-256 standard vector',function() equal(PBT.SHA256('abc'),'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad') end)
test('seven-bag and deterministic queue',function()
 local a,b=E.New(18),E.New(18);local seen={}
 for i=1,7 do equal(a.piece,b.piece);assert(not seen[a.piece]);seen[a.piece]=true;a:Spawn();b:Spawn() end
end)
test('hold once until locking',function() local e=E.New(9);local first=e.piece;assert(e:Hold());equal(e.hold,first);assert(not e:Hold());e:Drop();assert(e:Hold());equal(e.piece,first) end)
test('wall boundary and rotation',function() local e=E.New(3);e.piece='T';e.y=8;for _=1,20 do e:Move(-1) end;equal(e.x,1);assert(e:Rotate(1));assert(e:Rotate(-1));assert(e:Fits(e.x,e.y,e.rotation)) end)
test('four lines, score and garbage',function() local e=setupClear(4);e:Lock();equal(e.lines,4);equal(e.score,800);equal(e.sent,4);equal(e:Height(),0) end)
test('a clear hands the drawing side the rows as they stood',function()
 local e=setupClear(4);e:Lock()
 assert(e.wipe and e.wipe.quad,'four at once is marked for its own colour');equal(#e.board,22)
 local n=0;for y in pairs(e.wipe.clearing) do n=n+1;assert(y>=19 and y<=22) end;equal(n,4)
 equal(e.wipe.board[22][1],8);equal(e.wipe.board[22][5],E.ids.I)
 equal(e:Height(),0)
 local quiet=E.New(5);quiet.piece='O';quiet.x=5;quiet.y=20;quiet:Lock()
 assert(quiet.wipe==nil,'a lock that clears nothing leaves nothing to wipe')
end)
test('attacks cancel pending garbage',function() local e=setupClear(4,3);e:Lock();equal(e.sent,1);equal(e.pending,0);equal(e:Height(),0) end)
test('remaining garbage rises after lock',function() local e=setupClear(2,4);e:Lock();equal(e.sent,0);equal(e.pending,0);assert(e:Height()>=3);local holes=0;for x=1,10 do if e.board[22][x]==0 then holes=holes+1 end end;equal(holes,1) end)
test('garbage RNG does not alter piece queue',function() local a,b=E.New(7),E.New(7);a:AddGarbage(3);a:ApplyGarbage();for i=1,10 do a:Spawn();b:Spawn();equal(a.piece,b.piece) end end)
test('overflow loses',function() local e=E.New(1);e.board[1][1]=1;e:AddGarbage(1);e:ApplyGarbage();assert(e.over) end)
test('bounded huge garbage overflows',function() local e=E.New(1);e:AddGarbage(999999);e:ApplyGarbage();assert(e.over);equal(#e.board,22) end)
test('spawn obstruction loses',function() local e=E.New(1);for x=1,10 do e.board[1][x]=8;e.board[2][x]=8 end;e:Spawn();assert(e.over) end)
test('solo gravity accelerates',function() local a,b=E.New(1),E.New(1);b.level=10;for _=1,8 do a:Tick(.1);b:Tick(.1) end;assert(b.y>a.y) end)
test('pause stops input and timer',function() local e=E.New(1);local y,x,p=e.y,e.x,e.piece;e.paused=true;e:Tick(.1,true);e:Move(1);e:Rotate(1);e:Drop();e:Hold();equal(e.y,y);equal(e.x,x);equal(e.piece,p);equal(e.elapsed,0) end)
test('soft drop does not cash in the slow fall already due',function()
 local e=E.New(1);for _=1,8 do e:Tick(.1) end
 local y=e.y;equal(y,e.y)
 e:Tick(.1,true)
 assert(e.y-y<=4,'one soft drop frame moved '..(e.y-y)..' rows, which is a hard drop')
 assert(e.y>y,'and it still moves')
end)
test('a level up does not cash in the fall already due',function()
 local e=E.New(1);for _=1,8 do e:Tick(.1) end
 local y=e.y;e.level=10;e:Tick(.1)
 assert(e.y-y<=2,'one frame after a level up moved '..(e.y-y)..' rows')
end)
test('a level up announces itself once, and only when it happens',function()
 local e=setupClear(4);e.lines=8;local seen={};e.onEvent=function(kind) seen[#seen+1]=kind end
 e:Lock();equal(e.level,2)
 local levels=0;for _,kind in ipairs(seen) do if kind=='level' then levels=levels+1 end end
 equal(levels,1)
 local flat=setupClear(1);flat.onEvent=function(kind) assert(kind~='level','a clear without a level up says nothing') end
 flat:Lock();equal(flat.level,1)
end)
test('level increases each ten lines',function() local e=setupClear(4);e.lines=8;e:Lock();equal(e.level,2) end)
test('ghost lies on valid landing',function() local e=E.New(1);local y=e:GhostY();assert(e:Fits(e.x,y,e.rotation));assert(not e:Fits(e.x,y+1,e.rotation)) end)
local now,queue,players,allowed,drop
local function network()
 now=100;queue={};players={};allowed=true;drop=false
 for _,name in ipairs({'A','B'}) do
  players[name]=PBT.Match.New({name=name,now=function() return now end,wall=function() return math.floor(now)+100000 end,random=function() return name=='A' and 1234 or 4321 end,allowed=function() return allowed end,
  send=function(peer,p) if not drop then queue[#queue+1]={sender=name,peer=peer,p=p} end;return true end})
 end
end
local function flush() local limit=100;while #queue>0 do limit=limit-1;assert(limit>0);local q=table.remove(queue,1);players[q.peer]:Receive(q.sender,q.p) end end
local function advance(n) for _=1,n*10 do now=now+.1;players.A:Tick(.1);players.B:Tick(.1);flush() end end
local function start() network();players.A:Invite('B');flush();equal(players.B.state,'invited');players.B:Accept();flush();advance(9);equal(players.A.state,'playing');equal(players.B.state,'playing') end
test('idle tick is safe',function() network();advance(1) end)
test('handshake produces identical sequence',function() start();equal(players.A.engine.piece,players.B.engine.piece);equal(players.A.seed,players.B.seed) end)
test('cumulative attacks survive duplicates and reordering',function()
 start();players.A.engine.sent=4;local old=players.A:Packet(5);players.B:Receive('A',old);players.B:Receive('A',old);equal(players.B.engine.pending,4)
 players.A.engine.sent=7;players.B:Receive('A',players.A:Packet(5));players.B:Receive('A',old);equal(players.B.engine.pending,7)
end)
test('lost attack snapshot recovered on retry',function() start();drop=true;players.A.engine.sent=3;advance(2);equal(players.B.engine.pending,0);drop=false;advance(2);equal(players.B.engine.pending,3) end)
test('topout gives opposite results',function() start();players.A.engine.over=true;advance(1);equal(players.A.result,'あなたの負け');equal(players.B.result,'あなたの勝ち！') end)
test('simultaneous topout is reconciled',function() start();players.A.engine.over=true;players.B.engine.over=true;players.A:Tick(.1);players.B:Tick(.1);flush();advance(2);equal(players.A.result,'同時終了・引き分け');equal(players.B.result,'同時終了・引き分け') end)
test('local topout reconciles before next tick',function() start();players.A.engine.over=true;players.B.engine.over=true;players.A:Tick(.1);flush();equal(players.B.result,'同時終了・引き分け');advance(2);equal(players.A.result,'同時終了・引き分け') end)
test('quit forfeits',function() start();players.A:Quit();flush();equal(players.B.result,'あなたの勝ち！') end)
test('disconnect aborts without assigning winner',function() start();drop=true;advance(17);equal(players.A.state,'aborted');equal(players.B.state,'aborted');equal(players.A.result,nil) end)
test('group loss aborts',function() start();allowed=false;advance(1);equal(players.A.state,'aborted') end)
test('unaccepted invitation expires',function() network();players.A:Invite('B');flush();advance(31);equal(players.A.state,'aborted') end)
test('start acknowledgement loss cannot start guest alone',function() network();players.A:Invite('B');flush();drop=true;players.B:Accept();advance(31);assert(players.A.state~='playing');assert(players.B.state~='playing') end)
test('unsolicited and malformed packets ignored',function() start();local p=players.A:Packet(5);p.attack=10;players.B:Receive('X',p);equal(players.B.engine.pending,0);p.attack=-1;players.B:Receive('A',p);equal(players.B.engine.pending,0) end)
test('second match resets final transmission lifetime',function() start();players.A:Quit();flush();advance(21);players.A.o.random=function() return 9876 end;players.A:Invite('B');flush();players.B:Accept();flush();advance(9);equal(players.A.state,'playing');equal(players.A.untilTime,nil);players.A:Quit();flush();assert(players.A.untilTime>now) end)
test('old invite cannot replace finished match',function() start();local invite=players.A:Packet(1);players.A:Quit();flush();players.B:Receive('A',invite);equal(players.B.state,'result') end)
test('simultaneous invites converge',function() network();players.A:Invite('B');players.B:Invite('A');flush();equal(players.A.state,'inviting');equal(players.B.state,'invited');players.B:Accept();flush();advance(9);equal(players.A.state,'playing');equal(players.B.state,'playing') end)
-- Contracts for the game's actual menu table, including coexistence with another PX child.
ZO_GamepadEntryData={New=function(_,name,icon) return {SetIconTintOnSelection=function() end,SetIconDisabledTintOnSelection=function() end,SetEnabled=function() end} end}
dofile('PBsTetris/Menu.lua')
test('PX sits between help and options with idempotent children',function()
 ZO_MENU_ENTRIES={{id=1,data={name='ヘルプ',scene='helpRootGamepad'}},{id=2,data={name='設定',scene='gamepad_options_root'}},{id=3,data={name='ログアウト'}}}
 local launched,forced=0,nil;local app={Solo=function(_,restart,force) launched=launched+1;forced=force end}
 PBT.EnsureMenu(app);PBT.EnsureMenu(app)
 equal(#ZO_MENU_ENTRIES,4);equal(ZO_MENU_ENTRIES[4].id,3)
 equal(ZO_MENU_ENTRIES[1].data.name,'ヘルプ');equal(ZO_MENU_ENTRIES[2].data.name,'ゲームセンターPX');equal(ZO_MENU_ENTRIES[3].data.name,'設定')
 equal(#ZO_MENU_ENTRIES[2].subMenu,2)
 ZO_MENU_ENTRIES[2].subMenu[1].data.activatedCallback();equal(launched,1);equal(forced,false)
 ZO_MENU_ENTRIES[2].subMenu[2].data.activatedCallback();equal(forced,true)
end)
test('existing PX games retained',function()
 ZO_MENU_ENTRIES={{id=2,data={scene='gamepad_options_root'}},{id='other',data={name='ゲームセンターPX',subMenu={{name='別のゲーム'}}},subMenu={{id='othergame',data={name='別のゲーム'}}}}}
 PBT.EnsureMenu({});equal(#ZO_MENU_ENTRIES,2);equal(#ZO_MENU_ENTRIES[2].subMenu,3)
end)
print(string.format('%d tests passed',count))
dofile('tests/integration.lua')
dofile('tests/audio.lua')
dofile('tests/gravity20g.lua')
