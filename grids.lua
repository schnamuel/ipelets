label = "Generate grid subgraphs"


local function key(x, y)
    return x .. ";" .. y
end

local function getCoordinates(key)
    return key:match("([^;]+);([^;]+)")
end


local function get_candidates_strong_product(key,offset)
    local candidates = {}
    local x, y = getCoordinates(key)
    candidates[1] = x + offset .. ";" .. y
    candidates[2] = x + offset .. ";" .. y + offset
    candidates[3] = x .. ";" .. y + offset
    candidates[4] = x - offset .. ";" .. y + offset
    return candidates
end

local function get_candidates_cartesian_product(key,offset)
    local candidates = {}
    local x, y = getCoordinates(key)
    candidates[1] = x + offset .. ";" .. y
    candidates[2] = x .. ";" .. y + offset
    return candidates
end


--computes the color the edge is assigned as the average of the marks it connects
local function getColor(sheets, color1, color2)
    local color1 = sheets:find("color", color1)
    local color2 = sheets:find("color", color2)
    return {r=(color1.r + color2.r)/2,g=(color1.g + color2.g)/2,b=(color1.b + color2.b)/2}
end

function run(model, num)
    local p = model:page()
    local s = model:getString("Enter the distance between two horizontally or vertically adjacent vertices", "Create grid", model.snap.gridsize)
    local offset = tonumber(s)
    if not offset then 
        model:warning("Please enter a valid number.")
        return
    end

    if offset <= 0 then
        model:warning("Please enter a number larger than 0.")
        return
    end
    local sheets = model.doc:sheets()
    local marks = {}

    --add all marks in a table
    for _,i in ipairs(model:selection()) do
        if p[i]:type() == "reference" then
            local position = p[i]:matrix() * p[i]:position()
            
            -- if the marks have a fill color, e.g., they are fdisk, use this color. Otherwise use the stroke color
            if p[i]:get("fill") ~= "undefined" then
                marks[key(position.x,position.y)] = p[i]:get("fill")
            else
                marks[key(position.x,position.y)] = p[i]:get("stroke")
            end
        end
    end

    local edges = {}
    
    for key, color in pairs(marks) do

        --find coordinates of potential neighbors

        local candidates = methods[num].get_candidates(key,offset)

        for _, candidate in ipairs(candidates) do

            --check whether these neighbors exist
            if marks[candidate] ~= nil then
                local pos1 = ipe.Vector(getCoordinates(key))
                local pos2 = ipe.Vector(getCoordinates(candidate))
                local curve = { type="curve", closed = false, {type="segment", pos2,pos1} }
                local a = model.attributes
                a.stroke = getColor(sheets,color, marks[candidate])
                edges[#edges+1] = ipe.Path(model.attributes, { curve } )
            end
        end 
    end

    local t = { 
        label = methods[num].label,
	    pno = model.pno,
	    original = model:page():clone(),
	    undo = _G.revertOriginal,
        edges = edges,
        layer = p:layerOf(p:primarySelection())
    }
    t.redo = function(t, doc)
    local p = doc[t.pno]
    for _,edge in ipairs(edges) do
        p:insert(nil, edge, 0, t.layer)
    end
    
end
    model:register(t)
end

methods = {
    { label = "generate induced strong grid subgraph", get_candidates=get_candidates_strong_product},
    { label = "generate induced grid subgraph", get_candidates=get_candidates_cartesian_product},
  }

--------------------------
