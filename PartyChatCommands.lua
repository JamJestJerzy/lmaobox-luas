local prefix = "!"

local ProtoBuf = (function()
	local a={}local b={Varint=0,Fixed64=1,LengthDelimited=2,StartGroup=3,EndGroup=4,Fixed32=5}local function c(table,d)d=d or 0;for e,f in pairs(table)do if type(f)=="table"then print(string.rep(" ",d)..e.." = {")c(f,d+2)print(string.rep(" ",d).."}")elseif type(f)=="string"then print(string.rep(" ",d)..e.." = \""..f.."\"")else print(string.rep(" ",d)..e.." = "..f)end end end;local function g(h,i,f)local j=h[i]if j then if type(j)=="table"then table.insert(j,f)else h[i]={j,f}end else h[i]=f end end;local function k(l,m)local f,n=0,string.byte;f=n(l,m)|(n(l,m+1)<<8)|(n(l,m+2)<<16)|(n(l,m+3)<<24)return f end;local function o(l,m)local f,p=0,0;repeat local q=string.byte(l,m)f=f+q&0x7F<<p;p=p+7;m=m+1 until q<128;return f,m end;local function r(l,m)return k(l,m),m+4 end;local function s(l,m)local f=k(l,m)m=m+4;f=f|(k(l,m)<<32)m=m+4;return f,m end;local function t(l,m)local u=0;u,m=o(l,m)local f=string.sub(l,m,m+u-1)m=m+u;return f,m end;local function v(l,m)local w,i,x=0,0,0;local y={}local f=nil;while m<#l do w,m=o(l,m)i=w>>3;x=w&0x07;if x==b.Varint then f,m=o(l,m)g(y,i,f)elseif x==b.Fixed64 then f,m=s(l,m)g(y,i,f)elseif x==b.LengthDelimited then f,m=t(l,m)if string.byte(f,1)==0x0A then f=v(f,1)end;g(y,i,f)elseif x==b.StartGroup then m=m+1 elseif x==b.EndGroup then m=m+1 elseif x==b.Fixed32 then f,m=r(l,m)g(y,i,f)else print("Unknown wire type: "..x)break end end;return y end;function a.Decode(l,m)m=m or 1;return v(l,m)end;function a.Dump(l)local z={}for A=1,#l do local q=string.byte(l,A)z[A]=string.format("%02X",q)end;print(table.concat(z," "))end;return a
end)()

local function startsWith (str, start)
    return string.sub(str, 1, string.len(start)) == start
end

local function removePrefix (str)
    local prefixLength = string.len(prefix)
    return string.sub(str, prefixLength + 1)
end

local function createCommand (aliases, callback, description)
    if description == nil then
        description = ""
    end
    return {
        name = aliases[1],
        aliases = aliases,
        execute = callback,
        description = description
    }
end

local function say_party (str)
    client.Command(string.format("tf_party_chat \"%s\"", str:gsub("\"", "")), true)
end

-- Register commands here
local commands = {
    createCommand({ "requeue", "queue", "q", "rq" }, function ()
        if steam.GetSteamID() ~= party.GetLeader() then
            return
        end

        local casual = party.GetAllMatchGroups()["Casual"]
        local reasons = party.CanQueueForMatchGroup( casual )
        if reasons == true then
            party.QueueUp( casual )
        else
            for k,v in pairs( reasons ) do
                say_party(v)
            end
        end
    end, "queues into casual match")
}

local function getCommand (name)
    for _, command in ipairs(commands) do
        for _, alias in ipairs(command.aliases) do
            if alias == name then
                return command
            end
        end
    end
end

local function executeCommand (name)
    local args = {}
    for word in name:gmatch("%S+") do table.insert(args, word) end
    name = args[1]
    table.remove(args, 1)

    getCommand(name).execute(args)
end

callbacks.Register("GCRetrieveMessage", "catt_gc_recv", function(typeID, data)
	if typeID == 6563 then -- k_EMsgGCParty_ChatMsg
		local data = ProtoBuf.Decode(data:Get())
		local username = steam.GetPlayerName(data[2])
		local message = data[3]

		print(string.format("(Party) %s: %s", username, message))
        
        if startsWith(message, prefix) then
            local command = removePrefix(message)
            executeCommand(command)
        end
    end

	return E_GCResults.k_EGCResultOK
end)