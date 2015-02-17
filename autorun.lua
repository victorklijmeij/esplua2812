--Simple Json parsing named string/integer
function fromJson(MSG)
   local hashMap = {}
   for k,v in string.gmatch(MSG,'"(%w+)":"(%w+)",') do
      hashMap[k] = v;
   end
   for k,v in string.gmatch(MSG,'"(%w+)":(%w+),') do
      hashMap[k] = v;
   end
   for k,v in string.gmatch(MSG,'"(%w+)":"(%w+)"}') do
      hashMap[k] = v;
   end
   for k,v in string.gmatch(MSG,'"(%w+)":(%w+)}') do
      hashMap[k] = v;
   end
   return hashMap
end

-- Range function
function range(from, to, step)
  step = step or 1
  return function(_, lastvalue)
    local nextvalue = lastvalue + step
    if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
       step == 0
    then
      return nextvalue
    end
  end, nil, from - step
end

colorstring={}
-- Led adress 1-100
function getColorstring(r,g,b,lstart,lend)
     lstart=lstart-1
     lend=lend-1
     local color=string.char(g,r,b)
     for i in range(lstart,lend)
     do
          colorstring[i]=color
     end
     local rs=""
     for i in range(0,99) 
     do
          rs=rs..colorstring[i]
     end     
     return rs
end

-- Reset LEDbar
gpio.ws2812(getColorstring(0,0,0,1,100))
--gpio.ws2812(string.char(0,0,0):rep(100))

-- Check connectivity
if wifi.sta.getip() then
     espid=wifi.sta.getip()
     -- light up first LED green as OK indicator
     gpio.ws2812(string.char(20,0,0))

     -- A simple http server
     srv=net.createServer(net.TCP)
       srv:listen(80,function(conn)
          conn:on("receive",function(conn,payload)
               -- Parse request
               local _, _, method, url, vars = string.find(payload, "([A-Z]+) (.+)?(.+) HTTP")
               if(method == nil)then
                  _, _, method, url = string.find(payload, "([A-Z]+) (.+) HTTP");
               end

               -- Handle POST
               if method == "POST" then
                    if payload == nil then
                         conn:send("HTTP/1.1 404 File Not Found")
                         conn:close()
                    else
                         body = payload:match("{.*}")
                         if body == nil then
                              conn:send("HTTP/1.1 418 I'm a teapot")
                         else
                              r=fromJson(body).red+0
                              g=fromJson(body).green+0
                              b=fromJson(body).blue+0
                              ledstart=fromJson(body).ledstart+0
                              ledend=fromJson(body).ledend+0
                              if r>=0 and r<256 and g>=0 and g<256 and b>=0 and b<256 
                                 and ledstart >=1 and ledend<=100 then
                                   gpio.ws2812(getColorstring(r,g,b,ledstart,ledend))
                                   conn:send("HTTP/1.1 200 OK")
                              else
                                   conn:send("HTTP/1.1 418 I'm a teapot")
                              end
                         end
                    end

              -- Handle PUT
               elseif method == "PUT" then
                    conn:send("HTTP/1.1 405 Method Not Allowed")

               -- Handle DELETE
               elseif method == "DELETE" then
                    conn:send("HTTP/1.1 405 Method Not Allowed")

               -- Handle GET
               elseif method == "GET" then
                    --Content-Type: application/javascript
                    if url=="/" then
                         page = "index.html"
                    else
                         page = string.sub(url,2)
                    end

                    --Mimetype
                    extension=page:match("%.(%a+)")
                    if extension == "js" then
                         conn:send("Content-Type: application/javascript\r\r")
                    end

                    print("debug: "..page)
                    -- Read chunks not exceeding 1490 bytes and sent to client
                    if file.open(page, "r") then
                         local line=""
                         continue=true
                         Seekindex=0
                         while continue do
                              file.seek("set", Seekindex)
                              line=file.read(512)
                              if (string.len(line)==512) then
                                   continue=true
                              else
                                   continue=false
                              end
                              Seekindex = Seekindex + 512
                              conn:send(line)
                         end
                         file.close()
                    else
                         conn:send("<h1>Darn, 404 page not found</h1>")
                         -- conn:send("HTTP/1.1 404 File Not Found")
                    end
               conn:send("")

               -- Handle unknown
               else
                    conn:send("HTTP/1.1 403 Forbidden")
                end
       end)

       conn:on("sent",function(conn)
            conn:close()
       end)

     end)
else
     -- Init failed no ip adress
     -- light up first LED red as Failure indicator
     gpio.ws2812(string.char(0,100,0))
end
