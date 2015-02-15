-- Reset LEDbar
gpio.ws2812(string.char(0,0,0):rep(62))

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
                         print("debug: No payload")
                         conn:send("HTTP/1.1 404 File Not Found")
                         conn:close()
                    else
                         body = payload:match("{.*}")
                         if body == nil then
                              print(payload)
                         else
                              print(body)
                              g, r, b = body:match("(%d+),(%d+),(%d+)")
                              gpio.ws2812(string.char(g,r,b):rep(62))
                              conn:send("HTTP/1.1 200 OK")
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
                    if url=="/" then
                         page = "index.html"
                    else
                         page = string.sub(url,2)
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
     print "debug: Init failed no ip adress"
     print "debug: Check station mode and ap settings"

     -- light up first LED red as Failure indicator
     gpio.ws2812(string.char(0,100,0))
end
