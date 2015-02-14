-- Reset LEDbar
gpio.ws2812(string.char(0,0,0):rep(10))

-- Check connectivity
if wifi.sta.getip() then
     espid=wifi.sta.getip()

     -- light up first LED green as OK indicator
     gpio.ws2812(string.char(20,0,0))

     -- A simple http server
     srv=net.createServer(net.TCP) 
     srv:listen(80,function(conn) 
          -- conn:on("sent",function(conn) conn:close() end)
          conn:on("receive",function(conn,payload) 
               -- Parse request
               local _, _, method, path, vars = string.find(payload, "([A-Z]+) (.+)?(.+) HTTP")
               if(method == nil)then 
                  _, _, method, path = string.find(payload, "([A-Z]+) (.+) HTTP"); 
               end
     
               -- Handle POST
               if method == "POST" then
                    if payload == nil then
                         print("debug: No payload")
                    else
                         json = "{.*}"
                         body = payload:match("{.*}")
                         g, r, b = body:match("(%d+),(%d+),(%d+)")
                         gpio.ws2812(string.char(g,r,b):rep(10))
                    end
                    conn:close()
              -- Handle PUT
               elseif method == "PUT" then
                    conn:close()
               -- Handle DELETE
               elseif method == "DELETE" then
                    conn:close()
               -- Handle GET
               elseif method == "GET" then
                    file.open("index.html", "r")
                    body=file.read()
                    conn:send(body)         
                    file.close()
                    conn:close()
               -- Handle Unknown
               else
                 conn:close()
               end         
          end) 
     end)
else
     print "debug: Init failed no ip adress" 
     print "debug: Check station mode and ap settings" 

     -- light up first LED red as Failure indicator
     gpio.ws2812(string.char(0,100,0))
end

