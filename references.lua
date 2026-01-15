 
local bg_layer = "background_references"
local no_references_layer = "no_references"

----------------------------------------------------------------------
-- adding objects before every run of latex ---------------------

-- saving the old function
function _G.MODEL:references_backup_runLatex() end
_G.MODEL.references_backup_runLatex = _G.MODEL.runLatex

function _G.MODEL:runLatex()
   refresh_references(self)
   return self:references_backup_runLatex()
end

function is_presentation(model)
   local sheets = model.doc:sheets()
   for i=1,sheets:count() do
      local sheet = sheets:sheet(i)
      local name = sheet:name()
      if name ~= nil then
         if string.find(name, "presentation") then
            return true
         end
      end
   end
   return false
end

function refresh_references(model)
   local p1 = model.doc[1]

   if page_has_layer(p1, bg_layer) then
      local objects = find_objects(model)
      print_on_every_page(model, objects)
   else
      if #model.doc > 1 and is_presentation(model) then 
         p1:addLayer(bg_layer)
         make_layer_visible(p1, bg_layer)
         model:setPage()
      end
   end
end

function find_objects(model)
   res = {}
   p1 = model.doc[1]
   for i, obj, sel, layer in p1:objects() do
      if layer == bg_layer then
	    res[#res+1] = obj
      end
   end
   
   return res
end


function print_on_every_page(model, objects)
   local doc = model.doc
   -- first create the clones
   local clones = {}
   for i = 2, #doc do
      local clone_objs = {}
      for j, obj in ipairs(objects) do
	 clone_objs[j] = obj:clone()
      end
      clones[i] = clone_objs
   end
   
   -- then add the clones
   for i = 2, #doc do

      local p = doc[i]
      if not page_has_layer(p, no_references_layer) then 
         -- if the layer does not exists, create it
         if not page_has_layer(p, bg_layer) then
            p:addLayer(bg_layer)
            make_layer_visible(p, bg_layer)
         end
         
         -- lock the layer
         p:setLocked(bg_layer, true)

         -- remove all objects from the layer
         clear_layer(p, bg_layer)

         -- add the objects to the layer
         for j = 1, #objects do
            p:insert(nil, clones[i][j], nil, bg_layer)
         end

         if #objects == 0 then p:removeLayer(bg_layer) end
      end
   end
end


-- make a layer visible on all views of a page
function make_layer_visible(p, layer)
   for i = 1, p:countViews() do
      p:setVisible(i, layer, true)
   end
end

-- remove all objects in a given layer
function clear_layer(p, layer)
   local i = 1
   while i <= #p do
      if p:layerOf(i) == layer then
	 p:remove(i)
      else
	 i = i + 1
      end
   end
end

-- returns true if and only if the page p contains the given layer
function page_has_layer(p, layer)
   for _, layer_ in ipairs(p:layers()) do
      if layer == layer_ then
	 return true
      end
   end
   return false
end

----------------------------------------------------------------------
