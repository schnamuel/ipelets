label = "pick colors"  

function pick_colors(model)
    local p = model:page()
    local prim = p:primarySelection()
    if not prim then
        model.ui:explain("no selection")
        return
    end
    local obj = p[prim]
    local a = model.attributes
    a.stroke = obj:get("stroke")
    a.fill = obj:get("fill")
     model.ui:setAttributes(model.doc:sheets(), a)
end

function swap_colors(model)
    local p = model:page()
    local selection = model:selection()
    for _,i in ipairs(selection) do
        local fill = p[i]:get("fill")
        local stroke = p[i]:get("stroke")
        p[i]:set("fill", stroke)
        p[i]:set("stroke", fill)
    end
 end

 methods = {
    { label = "pick_colors", run = pick_colors},
    { label = "swap colors", run = swap_colors},
  }

shortcuts.ipelet_1_pick_colors= "Shift+Q"
shortcuts.ipelet_2_pick_colors= "Alt+Shift+C"