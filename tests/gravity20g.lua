local E=PBT.Engine
local function test(name,f) f();print('PASS 20G: '..name) end
local function occupied(e) local n=0;for _,row in ipairs(e.board) do for _,v in ipairs(row) do if v~=0 then n=n+1 end end end;return n end
test('spawn lands without locking or scoring',function() local e=E.New(1,false,true);assert(e:Grounded());assert(e.y>1);assert(occupied(e)==0);assert(e.score==0);e:Tick(.1);assert(occupied(e)==0) end)
test('locks after half a second',function() local e=E.New(1,false,true);for _=1,4 do e:Tick(.1) end;assert(occupied(e)==0);e:Tick(.1);assert(occupied(e)==4);assert(e:Grounded()) end)
test('sliding drops immediately off a ledge',function() local e=E.New(1,false,true);e.board[18][5]=8;e:Spawn('O');assert(e.y==16);assert(e:Move(1));assert(e.y==21 and e:Grounded()) end)
test('rotation and hold settle immediately',function() local e=E.New(1,false,true);e:Spawn('T');assert(e:Rotate(1));assert(e:Grounded());assert(e:Hold());assert(e:Grounded()) end)
test('15 resets prevent infinite stalling',function() local e=E.New(1,false,true);e:Spawn('O');for i=1,15 do e:Tick(.05);assert(e:Move(i%2==0 and 1 or -1)) end;assert(e.resets==15);for i=1,5 do e:Tick(.1);e:Move(i%2==0 and 1 or -1) end;assert(occupied(e)>=4) end)
test('blocked movement does not refresh timer',function() local e=E.New(1,false,true);for _=1,10 do e:Move(-1) end;e:Tick(.1);local lock=e.lock;assert(not e:Move(-1));assert(e.lock==lock) end)
test('level threshold lands current piece',function() local e=E.New(1);e.level=19;assert(not e:Is20G());e.level=20;e:Tick(0);assert(e:Is20G() and e:Grounded());assert(e.score==0) end)
test('normal play still falls over time',function() local e=E.New(1);assert(not e:Grounded());local y=e.y;e:Tick(.1);assert(e.y==y) end)
test('pause does not run lock timer',function() local e=E.New(1,false,true);e.paused=true;for _=1,10 do e:Tick(.1) end;assert(e.lock==0 and occupied(e)==0) end)
test('spawn collision still loses before instant drop',function() local e=E.New(1,false,true);for x=1,10 do e.board[1][x]=8 end;e:Spawn('O');assert(e.over) end)
