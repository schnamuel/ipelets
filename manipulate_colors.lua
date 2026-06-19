label = "manipulate colors"

function grayscale(color)
    local gray = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
    return {r=gray, g=gray, b=gray}
end

function invert_color(color)
    return {r=1-color.r, g=1-color.g, b=1-color.b}
end

function check_color(sheets, obj, attribute, color_function)
    local val = obj:get(attribute)
    val = sheets:find("color", val)
    obj:set(attribute, color_function(val)) 
end

function handle_groups(sheets, elements, color_function)
    for i=1,#elements do
            if elements[i]:type() ~= "group" then
                check_color(sheets, elements[i], "stroke",color_function)
                check_color(sheets, elements[i], "fill",color_function)
            else 
                elements[i] = ipe.Group(handle_groups(sheets, elements[i]:elements(),color_function))
            end
        end
        return elements
end


-- function run(model)
--     local doc = model.doc
--     local sheets = model.doc:sheets()

--     for j =1,#doc do
--         local p = doc[j]
--         for i, obj, _ , _  in p:objects() do
--             if obj:type() ~= "group" then
--                 check_color(sheets, obj, "stroke")
--                 check_color(sheets, obj, "fill")
--             else 
--                 p:replace(i, ipe.Group(handle_groups(sheets, obj:elements())))
--             end
--         end
--     end
-- end

function iterate(model,num)
    local p = model:page()
    local selection = model:selection()
    local sheets = model.doc:sheets()
    local t = {
         label = methods[num].label,
        pno = model.pno,
       selection = selection,
       sheets = sheets,
       original = p:clone(),
       undo = _G.revertOriginal
     }
    t.redo = function (t, doc)
        local p = doc[t.pno]
        for _,i in ipairs(selection) do
            if p[i]:type() ~= "group" then
                check_color(sheets, p[i], "stroke", methods[num].color_function)
                check_color(sheets, p[i], "fill", methods[num].color_function)
            else
                 p:replace(i, ipe.Group(handle_groups(sheets, p[i]:elements(), methods[num].color_function)))
            end
        end
    end
    model:register(t) 
end

methods = {
    { label = "grayscale", run = iterate, color_function = grayscale},
    { label = "invert color", run = iterate, color_function = invert_color},
}