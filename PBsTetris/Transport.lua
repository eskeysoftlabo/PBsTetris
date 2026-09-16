PBT=PBT or {}
local T={ID=510};T.__index=T;PBT.Transport=T
-- Development ID, distinct from PBsJanken's 511. Reserve before public release.
function T.Identity(name)
 local h=PBT.SHA256(name);return tonumber(h:sub(1,8),16),tonumber(h:sub(9,16),16)
end
function T:Allowed(peer)
 for i=1,GetGroupSize() do
  local tag=GetGroupUnitTagByIndex(i)
  if GetUnitDisplayName(tag)==peer then
   return peer~=GetDisplayName() and IsUnitOnline(tag) and not IsIgnored(peer)
    and CanCommunicateWith(GetUnitName(tag)) and not IsUnitInCombat("player") and not IsUnitInCombat(tag)
  end
 end
 return false
end
function T.New(receive)
 local self=setmetatable({},T)
 if not LibGroupBroadcast then self.error="対戦にはLibGroupBroadcastが必要です。";return self end
 local ok,err=pcall(function()
  local handler=assert(LibGroupBroadcast:RegisterHandler("PBsTetris"))
  handler:SetDisplayName("PB's Tamriel de Tetris")
  handler:SetDescription("グループ内で落ちものパズル対戦")
  local p=handler:DeclareProtocol(T.ID,"PBsTetrisV2Dev");self.protocol=p
  for _,field in ipairs({{"version",2},{"kind",3},{"target1",32},{"target2",32},{"session",32},{"seed",31},{"startAt",32},{"attack",16},{"height",5},{"terminal",2}}) do
   p:AddField(LibGroupBroadcast.CreateNumericField(field[1],{numBits=field[2]}))
  end
  local a,b=T.Identity(GetDisplayName())
  p:OnData(function(tag,data)
   if data.version~=2 or data.target1~=a or data.target2~=b then return end
   local peer=GetUnitDisplayName(tag)
   if self:Allowed(peer) then receive(peer,data) end
  end)
  assert(p:Finalize({isRelevantInCombat=false,replaceQueuedMessages=false}))
 end)
 if not ok then self.protocol=nil;self.error="対戦通信を初期化できません。/pbt debug で詳細を確認できます。";self.detail=tostring(err) end
 return self
end
function T:Send(peer,packet)
 if not self.protocol or not self.protocol:IsEnabled() or not self:Allowed(peer) then return false end
 local p={version=2};for k,v in pairs(packet) do p[k]=v end
 p.target1,p.target2=T.Identity(peer)
 return self.protocol:Send(p,{replaceQueuedMessages=false})==true
end
