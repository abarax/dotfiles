 -- Key binding
 local clipboard_menu_key = { {"cmd", "shift"}, "v" }
 -- Speed in seconds to check for clipboard changes. If you check
 -- too frequently, you will loose performance, if you check
 -- sparsely you will loose copies
 local frequency = 0.8
 -- How many items to keep on history
 local hist_size = 100
 -- How wide (in characters) the dropdown menu should be. Copies
 -- larger than this will have their label truncated and end with
 -- "…" (unicode for elipsis ...)
 local label_length = 70
 --asmagill request. If any application clears the pasteboard, we
 --also remove it from the history
 --https://groups.google.com/d/msg/hammerspoon/skEeypZHOmM/Tg8QnEj_N68J
 local honor_clearcontent = false
 -- Title to show on the menubar, if enabled above
 local menubar_title = "✂"


function bind(keyspec, fun)
   hs.hotkey.bind(keyspec[1], keyspec[2], fun)
end

-- Chooser/menu object
local chooser = nil
-- Cache for focused window to work around the current window losing focus after the chooser comes up
local prevFocusedWindow = nil

-- Don't change anything bellow this line
local pasteboard = require("hs.pasteboard") -- http://www.hammerspoon.org/docs/hs.pasteboard.html
local settings = require("hs.settings") -- http://www.hammerspoon.org/docs/hs.settings.html
local last_change = pasteboard.changeCount() -- displays how many times the pasteboard owner has changed // Indicates a new copy has been made

--Array to store the clipboard history
local clipboard_history = settings.get("so.victor.hs.jumpcut") or {} --If no history is saved on the system, create an empty history

function putOnPaste(value,key)
   if prevFocusedWindow ~= nil then
      prevFocusedWindow:focus()
   end
   if value == nil then return end
   if value.image ~= nil then
       pasteboard.setImageContents(value.image)
   else
       pasteboard.setContents(value.text)
   end
   last_change = pasteboard.changeCount()

   hs.eventtap.keyStroke({"cmd"}, "v")
end

-- Clears the clipboard and history
function clearAll()
   pasteboard.clearContents()
   clipboard_history = {}
   settings.set("so.victor.hs.jumpcut",clipboard_history)
   now = pasteboard.changeCount()
end

-- Clears the last added to the history
function clearLastItem()
   table.remove(clipboard_history,#clipboard_history)
   settings.set("so.victor.hs.jumpcut",clipboard_history)
   now = pasteboard.changeCount()
end

function pasteboardToClipboard(item)
   -- Loop to enforce limit on qty of elements in history. Removes the oldest items
   while (#clipboard_history >= hist_size) do
      table.remove(clipboard_history,1)
   end
   table.insert(clipboard_history, item)
   settings.set("so.victor.hs.jumpcut",clipboard_history) -- updates the saved history
end

populateChooser = function(key)
   menuData = {}
   if (#clipboard_history == 0) then
      table.insert(menuData, {text="", subtext = "Clipboard history is empty"}) -- If the history is empty, display "None"
   else
      for k,v in pairs(clipboard_history) do
         if (type(v) == "string") then
            table.insert(menuData,1, {text=v, subText=""})
         else
            if type(v) == "userdata" then
               table.insert(menuData,1, {text="(image)", subText = "", image=v })
            else
               table.insert(menuData,1, {text=v, subText = ""})
            end
         end -- end if else
      end-- end for
   end-- end if else
   return menuData
end

-- If the pasteboard owner has changed, we add the current item to our history and update the counter.
function storeCopy()
   now = pasteboard.changeCount()
   if (now > last_change) then
      current_clipboard = pasteboard.getContents()
      if (current_clipboard == nil) and (pasteboard.getImageContents ~= nil) then
         pcall(function() current_clipboard = pasteboard.getImageContents() end)
      end
      -- asmagill requested this feature. It prevents the history from keeping items removed by password managers
      if (current_clipboard == nil and honor_clearcontent) then
         clearLastItem()
      else
         pasteboardToClipboard(current_clipboard)
      end
      last_change = now
   end
end

chooser = hs.chooser.new(putOnPaste)
chooser:bgDark(true)

chooser:choices(populateChooser)

hs.hotkey.bind({"cmd", "shift"}, "v", function()

        chooser:refreshChoicesCallback()

        prevFocusedWindow = hs.window.focusedWindow()

        chooser:show()
    end)

--Checks for changes on the pasteboard. Is it possible to replace with eventtap?
timer = hs.timer.new(frequency, storeCopy)
timer:start()
