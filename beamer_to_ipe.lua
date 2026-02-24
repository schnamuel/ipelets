label="beamer to ipe"

about= [[Decomposes a textbox consisting of text inside itemize or enumeration evironments into singular items.]]

V = ipe.Vector

skip = 8.0

function ttb_skip(p, selection)
  local dy = { 0 }
  local ytarget = p:bbox(selection[1]):bottom() - skip
  for i = 2,#selection do
    local j = selection[i]
    dy[i] = ytarget - p:bbox(j):top()
    ytarget = ytarget - p:bbox(j):height() - skip
  end
  return dy
end

local styles = {"normal", "itemize", "enumerate"}

local function split_latex_semantic(input)
    local blocks = {}
    local types  = {}

    local function is_blank(str)
        return str:match("^%s*$") ~= nil
    end

    -- Split paragraphs outside environments
    local function split_paragraphs(text)
        local current = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do
            if is_blank(line) then
                if #current > 0 then
                    table.insert(blocks, table.concat(current, "\n"))
                    table.insert(types, 0)
                    current = {}
                end
            else
                table.insert(current, line)
            end
        end
        if #current > 0 then
            table.insert(blocks, table.concat(current, "\n"))
            table.insert(types, 0)
        end
    end

    -- Extract full environment (handles nesting of same type)
    local function extract_environment(str, start_pos, env)
        local pattern_begin = "\\begin%s*{%s*" .. env .. "%s*}"
        local pattern_end   = "\\end%s*{%s*" .. env .. "%s*}"

        local pos = start_pos
        local depth = 0

        while true do
            local next_begin = str:find(pattern_begin, pos)
            local next_end   = str:find(pattern_end, pos)

            if next_begin and (not next_end or next_begin < next_end) then
                depth = depth + 1
                pos = next_begin + 1
            elseif next_end then
                depth = depth - 1
                if depth == 0 then
                    local _, end_pos = str:find(pattern_end, next_end)
                    return str:sub(start_pos, end_pos), end_pos + 1
                end
                pos = next_end + 1
            else
                break
            end
        end
        return nil, nil
    end

    -- Split items inside environment
    local function split_items(env_text, list_type)
        local content = env_text
            :gsub("^.-\\begin%s*{%s*.-%s*}", "")
            :gsub("\\end%s*{%s*.-%s*}%s*$", "")

        local items = {}
        local positions = {}

        for pos in content:gmatch("()\\item") do
            table.insert(positions, pos)
        end

        for i = 1, #positions do
            local start_pos = positions[i]
            local end_pos = positions[i + 1] and (positions[i + 1] - 1) or #content
            local item_text = content:sub(start_pos, end_pos)

            if list_type == 2 then
                -- enumerate: prepend counter adjustment
                local counter_prefix =
                    "\\addtocounter{enumi}{" .. (i - 1) .. "}\n"
                item_text = counter_prefix .. item_text
            end

            table.insert(blocks, item_text)
            table.insert(types, list_type)
        end
    end

    local pos = 1
    local len = #input

    while pos <= len do
        local next_itemize = input:find("\\begin%s*{%s*itemize%s*}", pos)
        local next_enum    = input:find("\\begin%s*{%s*enumerate%s*}", pos)

        local env_start, env_type, type_id

        if next_itemize and (not next_enum or next_itemize < next_enum) then
            env_start = next_itemize
            env_type = "itemize"
            type_id = 1
        elseif next_enum then
            env_start = next_enum
            env_type = "enumerate"
            type_id = 2
        end

        if not env_start then
            split_paragraphs(input:sub(pos))
            break
        end

        if env_start > pos then
            split_paragraphs(input:sub(pos, env_start - 1))
        end

        local env_block, next_pos =
            extract_environment(input, env_start, env_type)

        if not env_block then break end

        split_items(env_block, type_id)

        pos = next_pos
    end

    return blocks, types
end

function run(model)
    local p = model:page()
	local prim = p:primarySelection()
    if not prim then
        model.ui:explain("no selection")
        return
    end
    if p[prim]:type() ~= "text" then
        model.ui:explain("selection is not text")
        return
    end
    local obj = p[prim]
    local text = p[prim]:text()
    local width = obj:get("width")
    local top = p:bbox(prim):top()
    local left = p:bbox(prim):left()
    local strings, types = split_latex_semantic(text)
    p:deselectAll()
    for i, part in ipairs(strings) do
        p:insert(nil, ipe.Text({textstyle=styles[types[i]+1], stroke="black",textsize = "normal"}, part, ipe.Vector(left,top-i), width), 2, p:layerOf(prim))
    end
    p:remove(prim)
    model:autoRunLatex()

    local selection = model:selection()

    local dy = ttb_skip(p,selection)

	     for i = 1,#selection do
	       local j = selection[i]
	       local dy = dy[i]
	       if dy ~= 0 then p:transform(j, ipe.Translation(V(0.0, dy))) end
	     end

end

-- methods = {
--     { label = "split itemize", run = split},
--   }


---------------------------------------------

shortcuts.ipelet_1_beamer_to_ipe = "Alt+X"