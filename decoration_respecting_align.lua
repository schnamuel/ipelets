label = "decoration respecting align"

revertOriginal = _G.revertOriginal

about = [[
This ipelet is a slight variation of the built in align ipelet that respects decorations
]]

V = ipe.Vector

skip = 8.0

----------------------------------------------------------------------
function bbox(obj, page)
   local objno = #page + 1
   page:insert(objno, obj, nil, page:layers()[1])
   local bbox = page:bbox(objno)
   page:remove(objno)
   return bbox
end

function get_offset(model,obj)
  local offsets = {}
  local box = bbox(obj, model:page())
  offsets[1] = box:top() - 200
  offsets[2] = 100 - box:bottom()
  offsets[3] = 100 - box:left()
  offsets[4] = box:right() - 300
  return offsets
end

function decoration_names(model)
   local sheets = model.doc:sheets()
   local symbols = sheets:allNames("symbol")
   local res = {}
   for _, name in pairs(symbols) do
      if name:find("decoration/") == 1 then
	 res[#res + 1] = name
      end
   end
   return res
end

function adjusted_bbox(model, sel)
  local p = model:page()
  local box = p:bbox(sel)
  local adj_box = {box:top(),box:bottom(),box:left(),box:right()}
  local obj = p[sel]
  local deco = obj:get("decoration")
  if obj:type() ~= "group" or deco == "normal" then
    return adj_box
  end
  local symbol = model.doc:sheets():find("symbol", deco)
  local offsets = get_offset(model, symbol:clone())
  adj_box[1] = adj_box[1] + offsets[1]
  adj_box[2] = adj_box[2] - offsets[2]
  adj_box[3] = adj_box[3] - offsets[3]
  adj_box[4] = adj_box[4] + offsets[4]
  return adj_box
end

function get_baseline(p, prim)

  local pref = p:bbox(prim):bottomLeft()
  local pobj = p[prim]
  if pobj:type() == "text" then
    pref = pobj:matrix() * pobj:position() 
    return pref
  end

  if pobj:type() == "group" then
    local elements = pobj:elements()
    for _,obj in ipairs(elements) do
      if obj:type() == "text" then
        pref = pobj:matrix() * obj:matrix() * obj:position()
        return pref
      end
    end
  end
  return pref
end


function set_skip(model)
  local str = model:getString("Enter skip in points")
  if not str or str:match("^%s*$") then return end
  local s = tonumber(str)
  if not s then
    model:warning("Enter distance between consecutive objects in points")
    return
  end
  skip = s
  model.ui:explain("set skip distance to " .. skip .. " points")
end

----------------------------------------------------------------------

function simple_align(model, num)
  local p = model:page()
  if not p:hasSelection() then model.ui:explain("no selection") return end

  local pin = {}
  local selection = {}
  for i, obj, sel, lay in p:objects() do
    if sel == 2 then
      pin[obj:get("pinned")] = true
      selection[#selection + 1] = i
    end
  end
  if #selection == 0 then
     if (num >= 1 and num <= 7) then
	page_align(model, num)
     else
	model.ui:explain("nothing to align")
     end
     return
  end

  if (pin.fixed or
      pin.horizontal and methods[num].need_h or
      pin.vertical and methods[num].need_v) then
    model:warning("Cannot align objects",
		  "Some object is pinned and cannot be moved")
    return
  end

  local prim = p:primarySelection()
  local pbox = p:bbox(prim)
  local p_adjusted = adjusted_bbox(model,prim)
  local pref = get_baseline(p, prim)

  local t = { label = "align " .. methods[num].label,
	      pno = model.pno,
	      vno = model.vno,
	      selection = selection,
	      original = p:clone(),
	      undo = revertOriginal,
	      p_adjusted = p_adjusted,
	      pref = pref,
	      fn = num,
        deco = deco,
        model = model,
	    }

  t.redo = function (t, doc)
	     local p = doc[t.pno]
	     for _,i in ipairs(t.selection) do
	       local box = adjusted_bbox(model, i)
         local ref = get_baseline(p,i)
	       local vx, vy = 0, 0
	       if (t.fn == 1) then        -- top
		 vy = t.p_adjusted[1] - box[1]
	       elseif (t.fn == 2) then    -- bottom
		 vy = t.p_adjusted[2] - box[2]
	       elseif (t.fn == 3) then    -- left
		 vx = t.p_adjusted[3] - box[3]
	       elseif (t.fn == 4) then    -- right
		 vx = t.p_adjusted[4] - box[4]
	       elseif (t.fn == 5) then    -- center
		 vx = 0.5 * ((t.p_adjusted[3] + t.p_adjusted[4]) -
			   (box[3] + box[4]))
		 vy = 0.5 * ((t.p_adjusted[2] + t.p_adjusted[1]) -
			   (box[2] + box[1]))
	       elseif (t.fn == 6) then    -- h center
		 vx = 0.5 * ((t.p_adjusted[3] + t.p_adjusted[4]) -
			   (box[3] + box[4]))
	       elseif (t.fn ==  7) then   -- v center
		 vy = 0.5 * ((t.p_adjusted[2] + t.p_adjusted[1]) -
			   (box[2] + box[1]))
	       elseif (t.fn == 8) then    -- baseline
		 vy = t.pref.y - ref.y
	       end
	       p:transform(i, ipe.Translation(V(vx, vy)))
	     end
	   end
  model:register(t)
end

----------------------------------------------------------------------

function page_align(model, num)
   local p = model:page()
   if not p:hasSelection() then model.ui:explain("no selection") return end

   local pin = {}
   local selection = {}
   for i, obj, sel, lay in p:objects() do
      if sel then
	 pin[obj:get("pinned")] = true
	 selection[#selection + 1] = i
      end
   end
   if #selection == 0 then model.ui:explain("nothing to align") return end

   if (pin.fixed or
	  pin.horizontal and methods[num].need_h or
       pin.vertical and methods[num].need_v) then
      model:warning("Cannot align objects", "Some object is pinned and cannot be moved")
      return
   end

   local layout = model.doc:sheets():find("layout")
   local pref = -layout.origin
   local pbox = ipe.Rect()
   pbox:add(pref)
   pbox:add(pref + layout.papersize)

   local t = { label = "align " .. methods[num].label,
	       pno = model.pno,
	       vno = model.vno,
	       selection = selection,
	       original = p:clone(),
	       undo = revertOriginal,
	       pbox = pbox,
	       pref = pref,
	       fn = num,
   }

   t.redo = function (t, doc)
      local p = doc[t.pno]
      for _,i in ipairs(t.selection) do
        local box = adjusted_bbox(model,i)
        local ref = {x = box[3], y = box[2]}
        local deco_adj = 0
        if (p[i]:type() == "text") then
            ref = p[i]:matrix() * p[i]:position()
        end
        local vx, vy = 0, 0
        if (t.fn == 5) then        -- center
            vx = 0.5 * ((t.pbox:left() + t.pbox:right()) -
            (box[3] + box[4]))
            vy = 0.5 * ((t.pbox:bottom() + t.pbox:top()) -
            (box[1] + box[2]))
        elseif (t.fn == 6) then    -- h center
            vx = 0.5 * ((t.pbox:left() + t.pbox:right()) -
            (box[3] + box[4]))
        elseif (t.fn ==  7) then   -- v center
            vy = 0.5 * ((t.pbox:bottom() + t.pbox:top()) -
            (box[2] + box[1]))
        elseif (t.fn == 1) then    --top
          local frame = doc:sheets():find("layout").framesize
          vy = frame.y -box[1]
        elseif (t.fn == 2) then    --bottom
          vy = -box[2]
        elseif (t.fn == 3) then    --left
            vx = -box[3]
        elseif (t.fn == 4) then    --right
          local frame = doc:sheets():find("layout").framesize
          vx = frame.x -box[4]
        end
        p:transform(i, ipe.Translation(V(vx, vy)))
            end
    end
   model:register(t)
end

----------------------------------------------------------------------

function sequence_align_setup(model, num, movement)
  local p = model:page()
  if not p:hasSelection() then model.ui:explain("no selection") return end

  local pin = {}
  for i, obj, sel, lay in p:objects() do
    if sel then pin[obj:get("pinned")] = true end
  end

  if pin.fixed or pin[movement] then
    model:warning("Cannot align objects",
		  "Some object is pinned and cannot be moved")
    return false
  end

  return true
end

----------------------------------------------------------------------

function ltr_skip(model, selection)
  local dx = { 0 }
  local xtarget = adjusted_bbox(model,selection[1])[4] + skip
  for i = 2,#selection do
    local j = selection[i]
    local box = adjusted_bbox(model,j)
    dx[i] = xtarget - box[3]
    xtarget = xtarget + box[4] - box[3] + skip
  end
  return dx
end

function ltr_equal_gaps(model, selection)
  local dx = { 0 }
  local total = 0.0
  for _,i in ipairs(selection) do 
    local box = adjusted_bbox(model,i)
    total = total + box[4] - box[3]
  end
  local skip = (adjusted_bbox(model,selection[#selection])[4]
	    - adjusted_bbox(model,selection[1])[3] - total) / (#selection - 1)

  local xtarget = adjusted_bbox(model,selection[1])[4] + skip
  for i = 2,#selection-1 do
    local j = selection[i]
    local box = adjusted_bbox(model,j)
    dx[i] = xtarget - box[3]
    xtarget = xtarget + box[4] - box[3] + skip
  end
  dx[#selection] = 0
  return dx
end

function ltr_grid(model, selection, doc)
  local dx = { 0 }
  local total = 0.0
  for _,i in ipairs(selection) do 
    local box = adjusted_bbox(model, i)
    total = total + box[4] - box[3]
  end
  local frame = doc:sheets():find("layout").framesize

  local skip = (frame.x - total) / (#selection + 1)

  local xtarget = skip
  for i = 1,#selection do
    local j = selection[i]
    local box = adjusted_bbox(model,j)
    dx[i] = xtarget - box[3]
    xtarget = xtarget + box[4] - box[3] + skip
  end
  return dx
end

function ltr_centers(model, selection)
  local dx = { 0 }
  local front = adjusted_bbox(model,selection[1])
  local rear = adjusted_bbox(model,selection[#selection])
  local fcenter = (front[3] + front[4]) / 2
  local rcenter = (rear[3] + rear[4]) / 2
  local step = (rcenter - fcenter) / (#selection - 1)
  for i = 2,#selection-1 do
    local box = adjusted_bbox(model,selection[i])
    local center = (box[3] + box[4]) / 2
    dx[i] = (fcenter + (i-1) * step) - center
  end
  dx[#selection] = 0
  return dx
end

function ltr_left(model, selection)
  local dx = { 0 }
  local front = adjusted_bbox(model, selection[1])
  local rear = adjusted_bbox(model,selection[#selection])
  local fleft = front[3]
  local step = (rear[3] - fleft) / (#selection - 1)
  for i = 2,#selection-1 do
    local box = adjusted_bbox(model,selection[i])
    dx[i] = (fleft + (i-1) * step) - box[3]
  end
  dx[#selection] = 0
  return dx
end

function ltr_right(p, selection)
  local dx = { 0 }
  local front = adjusted_bbox(model,selection[1])
  local rear = adjusted_bbox(model,selection[#selection])
  local fright = front[4]
  local step = (rear[4] - fright) / (#selection - 1)
  for i = 2,#selection-1 do
    local box = adjusted_bbox(model,selection[i])
    dx[i] = (fright + (i-1) * step) - box[4]
  end
  dx[#selection] = 0
  return dx
end

function ltr(model, num)
  if not sequence_align_setup(model, num, "horizontal") then return end

  local p = model:page()
  local selection = model:selection()
  table.sort(selection, function (a,b)
			  return (adjusted_bbox(model,a)[3] < adjusted_bbox(model,b)[3])
			end)

  if #selection == 1 or
    #selection == 2 and methods[num].compute ~= ltr_skip and methods[num].compute ~= ltr_grid then
    model.ui:explain("nothing to distribute")
    return
  end
  local dx = { }
  if methods[num].compute ~= ltr_grid then
    dx = methods[num].compute(model, selection)
  end

  

  local t = { label = methods[num].label,
	      pno = model.pno,
	      vno = model.vno,
	      selection = selection,
	      original = p:clone(),
	      undo = revertOriginal,
	      dx = dx,
	    }

  t.redo = function (t, doc)
	     local p = doc[t.pno]
       if methods[num].compute == ltr_grid then
        local dx = methods[num].compute(model, selection, doc)
        for i = 1,#t.selection do
          local j = t.selection[i]
          if dx[i] ~= 0 then p:transform(j, ipe.Translation(V(dx[i], 0.0))) end
        end
      else 
        for i = 1,#t.selection do
          local j = t.selection[i]
          local dx = t.dx[i]
          if dx ~= 0 then p:transform(j, ipe.Translation(V(dx, 0.0))) end
        end
      end
	     
	   end
  model:register(t)
end

----------------------------------------------------------------------

function ttb_skip(model, selection)
  local dy = { 0 }
  local box = adjusted_bbox(model, selection[1])
  local ytarget = box[2] - skip
  for i = 2,#selection do
    local j = selection[i]
    box = adjusted_bbox(model, selection[i])
    dy[i] = ytarget - box[1]
    ytarget = ytarget - box[1] + box[2] - skip
  end
  return dy
end

function btt_skip(model, selection)
  local dy = ttb_skip(model,selection)
  local diff = dy[#selection]
  for i =1,#selection do
    dy[i] = dy[i]-diff
  end
  return dy
end

function ttb_equal_gaps(model, selection)
  local dy = { 0 }
  local total = 0.0
  for _,i in ipairs(selection) do 
    local box = adjusted_bbox(model,i)
    total = total + box[1] - box[2]
   end
  local skip = (adjusted_bbox(model,selection[1])[1]
	    - adjusted_bbox(model,selection[#selection])[2]
	- total) / (#selection - 1)

  local ytarget = adjusted_bbox(model,selection[1])[2] - skip
  for i = 2,#selection-1 do
    local j = selection[i]
    local box = adjusted_bbox(model,j)
    dy[i] = ytarget - box[1]
    ytarget = ytarget - box[1] + box[2] - skip
  end
  dy[#selection] = 0
  return dy
end

function ttb_grid(model, selection, doc)
  local dy = {}
  local total = 0.0
  for _,i in ipairs(selection) do 
    local box = adjusted_bbox(model, i)
    total = total + box[1] - box[2]
  end
  local frame = doc:sheets():find("layout").framesize

  local skip = (frame.y - total) / (#selection + 1)

  local ytarget = skip
  for i = 1,#selection do
    local j = selection[i]
    local box = adjusted_bbox(model,j)
    dy[i] = ytarget - box[2]
    ytarget = ytarget + box[1] - box[2] + skip
  end
  return dy
end

function ttb_centers(model, selection)
  local dy = { 0 }
  local front = adjusted_bbox(model,selection[1])
  local rear = adjusted_bbox(model,selection[#selection])
  local fcenter = (front[1] + front[2]) / 2
  local rcenter = (rear[1] + rear[2]) / 2
  local step = (fcenter - rcenter) / (#selection - 1)
  for i = 2,#selection-1 do
    local box = adjusted_bbox(model,selection[i])
    local center = (box[1] + box[2]) / 2
    dy[i] = (fcenter - (i-1) * step) - center
  end
  dy[#selection] = 0
  return dy
end


function ttb_top(model, selection)
  local dy = { 0 }
  local front = adjusted_bbox(model,selection[1])
  local rear = adjusted_bbox(model,selection[#selection])
  local ftop = front[1]
  local step = (ftop - rear[1]) / (#selection - 1)
  for i = 2,#selection-1 do
    local box = adjusted_bbox(model,selection[i])
    dy[i] = (ftop - (i-1) * step) - box[1]
  end
  dy[#selection] = 0
  return dy
end

function ttb_bottom(model, selection)
  local dy = { 0 }
  local front = adjusted_bbox(model,selection[1])
  local rear = adjusted_bbox(model,selection[#selection])
  local fbottom = front[2]
  local step = (fbottom - rear[2]) / (#selection - 1)
  for i = 2,#selection-1 do
    local box = adjusted_bbox(model,selection[i])
    dy[i] = (fbottom - (i-1) * step) - box[2]
  end
  dy[#selection] = 0
  return dy
end

function ttb(model, num)
  if not sequence_align_setup(model, num, "vertical") then return end

  local p = model:page()
  local selection = model:selection()
  table.sort(selection, function (a,b)
			  return (adjusted_bbox(model,a)[1] > adjusted_bbox(model,b)[1])
			end)

  if #selection == 1 or
    #selection == 2 and methods[num].compute ~= ttb_skip and methods[num].compute ~= ttb_grid then
    model.ui:explain("nothing to distribute")
    return
  end
  local dy = { }
  if methods[num].compute ~= ttb_grid then
    dy = methods[num].compute(model, selection)
  end

  local t = { label = methods[num].label,
	      pno = model.pno,
	      vno = model.vno,
	      selection = selection,
	      original = p:clone(),
	      undo = revertOriginal,
	      dy = dy,
	    }

  t.redo = function (t, doc)
	     local p = doc[t.pno]

      if methods[num].compute == ttb_grid then
        local dy = methods[num].compute(model, selection, doc)
        for i = 1,#t.selection do
          local j = t.selection[i]
          if dy[i] ~= 0 then p:transform(j, ipe.Translation(V(0.0, dy[i]))) end
        end
      else 
        for i = 1,#t.selection do
          local j = t.selection[i]
          local dy = t.dy[i]
          if dy ~= 0 then p:transform(j, ipe.Translation(V(0.0 , dy))) end
        end
      end
    end
  model:register(t)
end

----------------------------------------------------------------------

methods = {
  { label = "align top", run = simple_align, need_v = true },
  { label = "align bottom", run = simple_align, need_v = true },
  { label = "align left", run = simple_align, need_h = true },
  { label = "align right", run = simple_align, need_h = true },
  { label = "align center", run = simple_align, need_v = true, need_h = true },
  { label = "align H center", run = simple_align, need_h = true },
  { label = "align V center", run = simple_align, need_v = true },
  { label = "align baseline", run = simple_align, need_v = true },
  { label = "distribute left to right", run=ltr, compute = ltr_skip },
  { label = "distribute horizontally", run=ltr, compute = ltr_equal_gaps },
  { label = "distribute H centers evenly", run=ltr, compute = ltr_centers },
  { label = "distribute left sides evenly", run=ltr, compute = ltr_left },
  { label = "distribute right sides evenly", run=ltr, compute = ltr_right },
  { label = "distribute top to bottom", run=ttb, compute = ttb_skip },
  { label = "distribute vertically", run=ttb, compute = ttb_equal_gaps },
  { label = "distribute V centers evenly", run=ttb, compute = ttb_centers },
  { label = "distribute top sides evenly", run=ttb, compute = ttb_top }, 
  { label = "distribute bottom sides evenly", run=ttb, compute = ttb_bottom }, 
  { label = "set skip...", run = set_skip },
  { label = "distribute horizontally in grid", run=ltr, compute = ltr_grid },
  { label = "distribute vertically in grid", run=ttb, compute = ttb_grid },
  { label = "distribute bottom to top", run=ttb, compute = btt_skip },
}

----------------------------------------------------------------------

--remapping shortcuts to decoration_respecting_align instead
shortcuts.ipelet_1_align = "8" --align top
shortcuts.ipelet_2_align = "Alt+Shift+B" --align bottom
shortcuts.ipelet_3_align = nil --align left
shortcuts.ipelet_4_align = "Alt+Shift+R" --align right
shortcuts.ipelet_5_align = nil
shortcuts.ipelet_6_align = nil
shortcuts.ipelet_7_align = nil
shortcuts.ipelet_10_align = "Ctrl+Alt+Shift+H" --distribute horizontally
shortcuts.ipelet_14_align = nil--distribute with skip
shortcuts.ipelet_15_align = "Ctrl+Alt+Shift+V" --distribute vertically

shortcuts.ipelet_1_decoration_respecting_align = "Shift+T" --align top
shortcuts.ipelet_2_decoration_respecting_align = "Shift+B" --align bottom
shortcuts.ipelet_3_decoration_respecting_align = "Shift+L" --align left
shortcuts.ipelet_4_decoration_respecting_align = "Shift+R" --align right
shortcuts.ipelet_5_decoration_respecting_align = "Shift+C" --align center
shortcuts.ipelet_6_decoration_respecting_align = "Shift+H" --align horizontally
shortcuts.ipelet_7_decoration_respecting_align = "Shift+V" --align vertically
shortcuts.ipelet_8_decoration_respecting_align = "2" --align baseline
shortcuts.ipelet_10_decoration_respecting_align = "Alt+Shift+H" --distribute horizontally
shortcuts.ipelet_14_decoration_respecting_align = "Alt+Shift+T" --distribute with skip
shortcuts.ipelet_15_decoration_respecting_align = "Alt+Shift+V" --distribute vertically
shortcuts.ipelet_20_decoration_respecting_align = "Alt+Shift+G" --distribute horizontally on grid
shortcuts.ipelet_21_decoration_respecting_align = "Ctrl+Alt+Shift+G" --distribute vertically on grid
shortcuts.ipelet_22_decoration_respecting_align = "Ctrl+Alt+Shift+T" --distribute with skip from bottom to top