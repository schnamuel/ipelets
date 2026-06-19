label = "arcs"

function connect_marks(model)
    local p = model:page()
    local selection = model:selection()
    local prim = p:primarySelection()
    if not prim then
        model.ui:explain("no selection")
        return
    end
    local sec = nil
    for _,i in ipairs(selection) do
        if i ~= prim then
            sec = i
            break
        end
    end
    if sec == nil then
        model.ui:explain("you need to select two marks")
        return
    end

    if p[prim]:type() ~= "reference" or p[sec]:type() ~= "reference" then
        model.ui:explain("you need to select two marks")
        return
    end

    local pos1 = p[prim]:matrix() * p[prim]:position()
    local pos2 = p[sec]:matrix() * p[sec]:position()
    local diff = pos1 - pos2
    local dist = diff:len() * 0.5
    local mid = pos1 - (diff * 0.5)
    local m = ipe.Matrix(dist, 0, 0, dist, mid.x, mid.y) 
    local a = ipe.Arc(m, pos2.x, pos2.y)
    local curve = { type="curve", closed = false, {type="arc", pos1,pos2, arc=a} }
    local obj = ipe.Path(model.attributes, { curve } )
    model:creation("create arc", obj)
end

function flip_arc(model)
    local p = model:page()
    local prim = p:primarySelection()
    if not prim then
        model.ui:explain("no selection")
        return
    end

    if p[prim]:type() ~= "path" then
        model.ui:explain("selection is not an arc")
        return
    end

    local shape = p[prim]:shape()
    if (#shape ~= 1 or shape[1].type ~= "curve") then
        model.ui:explain("selection is not an arc")
        return 
    end
    local pobj = p[prim]

    local t = { 
        label = "flip arc",
        pno = model.pno,
       prim = prim,
       pobj = pobj,
       original = p:clone(),
       undo = _G.revertOriginal
     }
    t.redo = function (t, doc)
        local matrix = p[prim]:matrix()
        local arc = shape[1][1].arc
        local pos1,pos2 = arc:endpoints()
        local arc = ipe.Arc(arc:matrix(),pos1.x,pos1.y)
        local curve = { type="curve", closed = false, {type="arc", pos2,pos1, arc=arc} }
        local obj = ipe.Path(model.attributes, { curve } )
        p:replace(prim,obj)
        p:transform(prim,matrix)
    end
    model:register(t) 
end

methods = {
    { label = "connect marks with arc", run = connect_marks},
    { label = "flip arc", run = flip_arc},
  }


shortcuts.ipelet_1_arcs = "Alt+Q"
shortcuts.ipelet_2_arcs = "Ctrl+Alt+Q"