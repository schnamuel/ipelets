label = "stars"

function run(model)
    local p = model:page()
    local selection = model:selection()
    local prim = p:primarySelection()
    if not prim then
        model.ui:explain("no selection")
        return
    end

    if p[prim]:type() ~= "reference" and p[prim]:type() ~= "text" then
        model.ui:explain("primary selection is not a reference or text object")
        return
    end
    local segments = {}
    local pos1 = p[prim]:matrix() * p[prim]:position()

    for _,i in ipairs(selection) do
        if i ~= prim and (p[i]:type() == "reference" or p[i]:type() == "text") then
            local pos2 = p[i]:matrix() * p[i]:position()
            local curve = { type="curve", closed = false, {type="segment", pos2,pos1} }
            segments[#segments + 1] = ipe.Path(model.attributes, { curve } )
        end
    end
    
    for _,seg in ipairs(segments) do
        p:insert(nil, seg, 0, p:layerOf(prim))
    end
end


shortcuts.ipelet_1_stars = "Ctrl+Alt+Shift+S"