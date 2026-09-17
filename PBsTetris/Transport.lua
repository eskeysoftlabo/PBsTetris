PBT=PBT or {}
local T={ID=510};T.__index=T;PBT.Transport=T
-- Development ID, distinct from PBsJanken's 511. Reserve before public release.
function T.Identity(name)
 local h=PBT.SHA256(name);return tonumber(h:sub(1,8),16),tonumber(h:sub(9,16),16)
end
function T:Find(peer)
 for i=1,GetGroupSize() do
  local tag=GetGroupUnitTagByIndex(i)
  if GetUnitDisplayName(tag)==peer then return tag end
 end
end
-- Every refusal comes back with the reason it was refused. A duel that does not start is
-- otherwise indistinguishable from one that was never invited.
function T:Check(peer,outgoing)
 if not peer or peer=="" then return false,"送信者の表示名を取得できません" end
 if peer==GetDisplayName() then return false,"自分自身宛です" end
 local tag=self:Find(peer)
 if not tag then return false,"相手が同じグループにいません" end
 if not IsUnitOnline(tag) then return false,"相手がオフラインです" end
 if IsIgnored(peer) then return false,"相手を無視リストに入れています" end
 if IsUnitInCombat("player") then return false,"自分が戦闘中です" end
 if IsUnitInCombat(tag) then return false,"相手が戦闘中です" end
 -- The platform's communication permission decides what this add-on sends out. It is not
 -- asked again about what arrives: the library only delivers from inside the player's own
 -- group, the payload is game state rather than anything a player wrote, and a permission
 -- that answers differently on each end would drop every packet with nothing to show for it.
 if outgoing and not CanCommunicateWith(GetUnitName(tag)) then return false,"この相手との通信が許可されていません" end
 return true
end
function T:Allowed(peer) local ok=self:Check(peer,true);return ok end
function T:AllowedFrom(peer) local ok=self:Check(peer,false);return ok end
function T.New(receive,refused)
 local self=setmetatable({},T)
 if not LibGroupBroadcast then self.error="対戦にはLibGroupBroadcastが必要です。";return self end
 local ok,err=pcall(function()
  local handler=assert(LibGroupBroadcast:RegisterHandler("PBsTetris"))
  handler:SetDisplayName("PB's Tamriel de Tetris")
  handler:SetDescription("グループ内で落ちものパズル対戦")
  local p=handler:DeclareProtocol(T.ID,"PBsTetrisV2Dev");self.protocol=p
  p:SetDisplayName("PB's Tamriel de Tetris")
  for _,field in ipairs({{"version",2},{"kind",3},{"target1",32},{"target2",32},{"session",32},{"seed",31},{"startAt",32},{"attack",16},{"height",5},{"terminal",2}}) do
   p:AddField(LibGroupBroadcast.CreateNumericField(field[1],{numBits=field[2]}))
  end
  -- Resolved on use rather than at load: this runs from EVENT_ADD_ON_LOADED, where the client
  -- can still answer an empty display name, and an identity built from one would reject every
  -- packet addressed to the player for the rest of the session with nothing to show for it.
  local name,a,b
  local function own()
   local current=GetDisplayName()
   if current and current~="" and current~=name then name=current;a,b=T.Identity(current) end
   return a,b
  end
  self.Own=own
  p:OnData(function(tag,data)
   self.heard=(self.heard or 0)+1
   local mine1,mine2=own()
   if data.version~=2 or data.target1~=mine1 or data.target2~=mine2 then self.misaddressed=(self.misaddressed or 0)+1;return end
   local peer=GetUnitDisplayName(tag)
   local ok,why=self:Check(peer,false)
   if not ok then
    self.refused=(self.refused or 0)+1;self.why="受信を弾きました："..why
    if refused then refused(why) end
    return
   end
   self.taken=(self.taken or 0)+1;receive(peer,data)
  end)
  assert(p:Finalize({isRelevantInCombat=false,replaceQueuedMessages=false}))
 end)
 if not ok then self.protocol=nil;self.error="対戦通信を初期化できません。/pbt debug で詳細を確認できます。";self.detail=tostring(err) end
 return self
end
function T:Send(peer,packet)
 if not self.protocol then self.why="通信が初期化されていません";return false end
 if not self.protocol:IsEnabled() then self.why="LibGroupBroadcastでこのアドオンの通信が無効になっています";return false end
 local ok,why=self:Check(peer,true)
 if not ok then self.why="送信できません："..why;return false end
 local p={version=2};for k,v in pairs(packet) do p[k]=v end
 p.target1,p.target2=T.Identity(peer)
 if self.protocol:Send(p,{replaceQueuedMessages=false})~=true then self.why="LibGroupBroadcastが送信を受け付けませんでした";return false end
 self.why=nil;self.sent=(self.sent or 0)+1;return true
end
function T:Report()
 if self.error then return (self.detail or self.error) end
 local mine1,mine2=self.Own and self.Own()
 return string.format('通信ID %d / 有効 %s / グループ %d人 / 自分 %s(%s,%s) / 送信 %d / 受信 %d（自分宛でない %d・拒否 %d・採用 %d）%s',
  T.ID,tostring(self.protocol and self.protocol:IsEnabled()),GetGroupSize() or 0,
  tostring(GetDisplayName()),tostring(mine1),tostring(mine2),
  self.sent or 0,self.heard or 0,self.misaddressed or 0,self.refused or 0,self.taken or 0,
  self.why and (' / 直近の失敗：'..self.why) or '')
end
