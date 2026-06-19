 
label = "Linecap" 

about = [[ Provides a shortcut to toggle the linecap of paths between "normal" and "round". ]]

local function set_linecap(model, num)
    local p = model:page()
    local selection = model:selection()
    local t = { 
        label = methods[num].label,
        pno = model.pno,
       selection = selection,
       style_name = style_name,
       original = p:clone(),
       undo = _G.revertOriginal
     }
    t.redo = function (t, doc)
        local p = doc[t.pno]
        for _,i in ipairs(selection) do
            if p[i]:type() == "path" then
                if num ==1 then
                    toggle_linecap(p[i])
                else
                    p[i]:set("linecap", methods[num].linecap)
                end
            end
        end
    end
    model:register(t) 
 end

 function toggle_linecap(obj)
    if obj:get("linecap") == "normal" then
        obj:set("linecap", "round")
    else
        obj:set("linecap", "normal")

    end
 end

methods = {
    { label = "toggle linecap", run = set_linecap},
    { label = "set linecap round", run = set_linecap, linecap = "round"},
    { label = "set linecap normal", run = set_linecap, linecap = "normal"},
  }

------

shortcuts.ipelet_1_linecap = "Alt+Shift+L"