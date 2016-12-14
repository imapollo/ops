-- Load IP range file into lua_shared_dict
-- Find ISP by the IP range, by binsearch
-- Use reqmonit to calculate QPS, latency etc

local reqmonit = require("reqmonit")
local request_time = ngx.now() - ngx.req.start_time()

function table.binsearch(t,value)
   if not t:get("length") then
      return nil
   end
   local iStart,iEnd,iMid = 1,t:get("length"),0
   while iStart <= iEnd do
      iMid = math.floor( (iStart+iEnd)/2 )
      if t:get('left'..iMid) > value then
         iEnd = iMid - 1
      elseif t:get('right'..iMid) < value then
         iStart = iMid + 1
      else
         return t:get('isp'..iMid)
      end
   end
end

function split(str, delimiter)
  if str==nil or str=='' or delimiter==nil then
    return nil
  end
  local result = {}
  for match in (str..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match)
  end
  return result
end

function ip_2_int(ip)
  local num = 0
  ip:gsub("%d+", function(s) num = num * 256 + tonumber(s) end)
  return num
end

function location_not_loaded()
  if ngx.shared.location_dict:get("loaded") then
    return false
  else
    return true
  end
end

if tonumber(ngx.var.status) >= 500 then
    reqmonit.stat_5xx(ngx.shared.statics_dict, svrname_key)
end

if location_not_loaded() then
  ngx.shared.location_dict:set("loaded", true)
  local index = 1
  for line in io.lines('IP_RANGE_FILE') do
    local ip_elements = split(line, " ")
    ngx.shared.location_dict:set("left"..index, ip_2_int(ip_elements[1]))
    ngx.shared.location_dict:set("right"..index, ip_2_int(ip_elements[2]))
    ngx.shared.location_dict:set("isp"..index, ip_elements[13])
    index = index + 1
  end
  ngx.shared.location_dict:set("length", index)
end

local isp = table.binsearch(ngx.shared.location_dict, ip_2_int(ngx.var.remote_addr))
if isp then
  reqmonit.stat(ngx.shared.statics_dict, isp, request_time)
end

if ngx.var.ssl_protocol then
  svrname_key = "https"
else
  svrname_key = "http"
end

reqmonit.stat(ngx.shared.statics_dict, svrname_key, request_time)

