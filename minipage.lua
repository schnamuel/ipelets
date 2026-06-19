label = "Minipage" 

style_ordering = {"normal","item","subitem","subsubitem"}

fixed = false

function get_next_style(style)
    index = _G.findIndex(style_ordering,style)
    if index == nil then
        return nil
    end
    if index == #style_ordering then
        return style_ordering[1]
    else
        return style_ordering[index + 1]
    end
end

function check_available_styles(model)
    local sheets = model.doc:sheets()
    local textstyles = sheets:allNames("textstyle")
    local available_styles = {}
    for _,style in ipairs(style_ordering) do
        if _G.findIndex(textstyles,style) ~= nil then
            table.insert(available_styles, style)
        end
    end
    style_ordering = available_styles
    fixed = true
end


local function style_names(model)
    local sheets = model.doc:sheets()
    return sheets:allNames("textstyle")
end

local function mainWindow(model)
    if model.ui.win == nil then
       return model.ui
    else
       return model.ui:win()
    end
 end

local function ask_for_style(model)
    local dialog = ipeui.Dialog(mainWindow(model), "Select a style.")
    local styles = style_names(model)
    dialog:add("sty", "combo", styles, 1, 1, 1, 2)
    dialog:add("ok", "button", { label="&Ok", action="accept" }, 2, 2)
    dialog:add("cancel", "button", { label="&Cancel", action="reject" }, 2, 1)
    local r = dialog:execute()
    if not r then return end
    local style_name = styles[dialog:get("sty")]
    return style_name
 end


function set_minipage(model,num)
	local p = model:page()
	local selection = model:selection()
    local bool = "false"
    local neg = "true"
    if num == 1 then
        bool = "true"
        neg = "false"
    end
    local label = "change minipages to labels"
    if num == 1 then
        label="change labels to minipages"
    end

    local t = { 
            label = label,
		   pno = model.pno,
		   selection = selection,
           bool = bool,
           neg = neg,
		 }

    t.redo = function (t, doc)
        local p = doc[t.pno]
        for _,i in ipairs(selection) do
            if p[i]:type() == "text" then
                p[i]:set("minipage", bool)
            end
        end
        model:autoRunLatex()
    end
    t.undo = function (t, doc)
        local p = doc[t.pno]
        for _,i in ipairs(selection) do
            if p[i]:type() == "text" then
                p[i]:set("minipage", neg)
            end
        end
        model:autoRunLatex()
    end
    model:register(t) 
end

-- function set_item(model)
--     check_available_styles(model)
-- 	local p = model:page()
-- 	local selection = model:selection()
--     local t = { 
--             label = "set to next style",
-- 		   pno = model.pno,
-- 		   selection = selection,
--            bool = bool,
--            neg = neg,
--            original = p:clone(),
--            undo = _G.revertOriginal
-- 		 }

--     t.redo = function (t, doc)
--         local p = doc[t.pno]
--         for _,i in ipairs(selection) do
--             if p[i]:type() == "text" then
--                 style = get_next_style(p[i]:get("textstyle"))
--                 if style == nil then
--                     model:warning("Style was not found.")
--                 else
--                     p[i]:set("textstyle", style)
--                 end
--             end
--         end
--     end
--     model:register(t) 
-- end

local function set_item(model)
    local p = model:page()
    local style_name = ask_for_style(model)
    if (not style_name) then return end
    local selection = model:selection()

    local t = { 
        label = "changed style",
        pno = model.pno,
       selection = selection,
       style_name = style_name,
       original = p:clone(),
       undo = _G.revertOriginal
     }
    t.redo = function (t, doc)
        local p = doc[t.pno]
        for _,i in ipairs(selection) do
            if p[i]:type() == "text" then
                    p[i]:set("textstyle", style_name)
            end
        end
        model:autoRunLatex()
    end
    model:register(t)
 end

methods = {
    { label = "change labels to minipages", run = set_minipage},
    { label = "change minipages to labels", run = set_minipage},
    { label = "set style to item", run = set_item},
    { label = "update available styles", run = check_available_styles},
  }

------
shortcuts.ipelet_1_minipage = "Ctrl+M"
shortcuts.ipelet_2_minipage = "Ctrl+Alt+M"
shortcuts.ipelet_3_minipage = "Ctrl+Alt+I"