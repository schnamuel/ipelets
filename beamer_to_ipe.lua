label="beamer to ipe"

about= [[Decomposes a textbox consisting of text inside itemize or enumeration evironments into singular items.]]

V = ipe.Vector

skip = 8.0

link_color = "cyan1"

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

local function split_latex_all(input)
    local blocks = {}
    local types  = {}

    local pos = 1
    local len = #input

    -- Patterns
    local patterns = {
        itemize   = "\\begin%s*{%s*itemize%s*}",
        enumerate = "\\begin%s*{%s*enumerate%s*}",
        columns   = "\\begin%s*{%s*columns%s*}"
    }

    local end_patterns = {
        itemize   = "\\end%s*{%s*itemize%s*}",
        enumerate = "\\end%s*{%s*enumerate%s*}",
        columns   = "\\end%s*{%s*columns%s*}"
    }

    ---------------------------------------------------
    -- Utility: extract full environment (nested safe)
    ---------------------------------------------------
    local function extract_environment(start_pos, env)
        local pattern_begin = patterns[env]
        local pattern_end   = end_patterns[env]

        local p = start_pos
        local depth = 0

        while true do
            local next_begin = input:find(pattern_begin, p)
            local next_end   = input:find(pattern_end, p)

            if next_begin and (not next_end or next_begin < next_end) then
                depth = depth + 1
                p = next_begin + 1
            elseif next_end then
                depth = depth - 1
                if depth == 0 then
                    local _, end_pos = input:find(pattern_end, next_end)
                    return input:sub(start_pos, end_pos), end_pos + 1
                end
                p = next_end + 1
            else
                break
            end
        end

        return nil, nil
    end



    ----------------------------------------
    -- Split list environment into items
    ----------------------------------------
    -- blocks and types are assumed global (as in split_latex_all)
-- blocks and types are assumed global (as in split_latex_all)
local function split_list(env_text, list_type)
    
    -- Remove outer \begin{itemize|enumerate}...\end{itemize|enumerate}
    local content = nil
    if list_type == 1 then
        content =env_text:sub(16,#env_text-13)
    else 
        content =env_text:sub(18,#env_text-15)
    end
    -- local content = string.gsub(env_text, "\\begin{" .. styles[list_type] .. "}", "", 1)
    
    -- local last_start, last_end = content:match("\\end{" .. styles[list_type] .. "}")
    -- local pos = nil
    -- -- Iterate through all matches to get the last one
    -- local s = 1
    -- while true do
    --     local start_idx, end_idx = content:find("\\end{" .. styles[list_type] .. "}", s, true)
    --     if not start_idx then break end
    --     pos = {start_idx, end_idx}
    --     s = end_idx + 1
    -- end

    -- if pos then
    --     -- Rebuild the string without the last occurrence
    --     content = content:sub(1, pos[1]-1) .. content:sub(pos[2]+1)
    -- end




    local pos = 1
    local len = #content
    local item_start = 1
    local depth = 0 -- track nested environments

    while pos <= len do
        -- look for the next LaTeX command
        -- print(content:sub(pos))
        local s, e, cmd = content:find("\\(%a+)", pos)
        if not s then break end

        if cmd == "begin" then
             depth = depth + 1
        elseif cmd == "end" then
            depth = depth - 1
        elseif cmd == "item" and depth == 0 then
            -- found a top-level \item
            -- if item_start then
                -- the previous item ends at s-1
                local block = content:sub(item_start, s-1)
                if list_type == 2 then
                    block = "\\addtocounter{enumi}{" .. (#blocks - (#blocks - 1)) .. "}\n" .. block
                end
                table.insert(blocks, block)
                table.insert(types, list_type)
            -- end
            item_start = s
        end

        pos = s + 1
    end

    -- last item
    -- if item_start then
        local block = content:sub(item_start)
        if list_type == 2 then
            block = "\\addtocounter{enumi}{" .. (#blocks - (#blocks - 1)) .. "}\n" .. block
        end
        table.insert(blocks, block)
        table.insert(types, list_type)
    -- end
end

    ----------------------------------------
    -- Main scanning loop
    ----------------------------------------
    while pos <= len do
        local next_positions = {}

        for name, pat in pairs(patterns) do
            local s = input:find(pat, pos)
            if s then
                table.insert(next_positions, {pos = s, env = name})
            end
        end

        table.sort(next_positions, function(a, b)
            return a.pos < b.pos
        end)

        local next_env = next_positions[1]

        -- No more environments → rest is normal text
        if not next_env then
            table.insert(blocks, input:sub(pos))
            table.insert(types, 0)
            break
        end

        -- Text before environment
        if next_env.pos > pos then
            table.insert(blocks, input:sub(pos, next_env.pos - 1))
            table.insert(types, 0)
        end

        -- Extract environment
        local env_block, next_pos =
            extract_environment(next_env.pos, next_env.env)

        if not env_block then break end

        if next_env.env == "itemize" then
            split_list(env_block, 1)

        elseif next_env.env == "enumerate" then
            split_list(env_block, 2)

        elseif next_env.env == "columns" then
            table.insert(blocks, env_block)
            table.insert(types, 3)
        end

        pos = next_pos
    end

    return blocks, types
end

local function split_columns_env_with_width(columns_env_string)
     local contents = {}
    local widths   = {}

    -- Remove outer columns environment
    local content = columns_env_string
        :gsub("^%s*\\begin%s*{%s*columns%s*}", "")
        :gsub("\\end%s*{%s*columns%s*}%s*$", "")

    local pattern_begin = "\\begin%s*{%s*column%s*}%b{}"
    local pattern_end   = "\\end%s*{%s*column%s*}"

    local pos = 1
    local len = #content

    while pos <= len do
        local start_pos, begin_end = content:find(pattern_begin, pos)
        if not start_pos then break end

        -- Default width
        local numeric_width = 0.5

        -- Extract width argument
        local begin_block = content:sub(start_pos, begin_end)
        local width_arg = begin_block:match("%b{}")

        if width_arg then
            width_arg = width_arg:sub(2, -2)                 -- remove { }
            width_arg = width_arg:match("^%s*(.-)%s*$")      -- trim

            local number_str = width_arg:match("^%d*%.?%d+")

            if number_str then
                local num = tonumber(number_str)
                if num then
                    numeric_width = num
                end
            end
        end

        local p = begin_end + 1
        local depth = 1

        while depth > 0 do
            local next_begin = content:find(pattern_begin, p)
            local next_end   = content:find(pattern_end, p)

            if next_begin and (not next_end or next_begin < next_end) then
                depth = depth + 1
                p = next_begin + 1
            elseif next_end then
                depth = depth - 1
                if depth == 0 then
                    local _, end_pos = content:find(pattern_end, next_end)

                    local inner = content:sub(begin_end + 1, next_end - 1)

                    table.insert(contents, inner)
                    table.insert(widths, numeric_width)

                    pos = end_pos + 1
                    break
                end
                p = next_end + 1
            else
                break
            end
        end
    end

    return contents, widths
end

local function has_real_content(str)
    if not str then return false end

    -- Remove whitespace (spaces, tabs, linebreaks)
    local cleaned = str:gsub("%s+", "")

    -- Remove \vspace{...}
    cleaned = cleaned:gsub("\\vspace%s*%b{}", "")

    -- Remove commands of the form \somethingSkip (case sensitive)
    cleaned = cleaned:gsub("\\%a-skip", "")

    -- If nothing remains → no real content
    if cleaned == "" then
        return false
    else
        return true
    end
end

function clean_string(input)
    local s = input
    local progress = true
    while progress do
        local start = s
        -- 1. Remove leading whitespace and line breaks
        s = s:gsub("^%s+", "")

        -- remove \pause
        s = s:gsub("\\pause", "")

        -- 2. Remove \vspace{"..."} commands
        s = s:gsub("\\vspace%s*%b{}", "")

        -- 3. Remove \"...skip commands
        s = s:gsub("\\%a-skip", "")

        -- 4. Replace multiple spaces with a single space
        -- s = s:gsub("%s%s%s+", " ")

        s = s:gsub("^[ \t]+", ""):gsub("\n[ \t]+", "\n")

        -- 5. Replace multiple line breaks with a single line break
        s = s:gsub("\n\n\n+", "\n\n")

        -- 6. Trim again to remove whitespace at start/end if needed
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        progress = (s ~= start)
    end

    return s
end

local function extract_link(string)
    local _,_, link = string:find("\\href{(.-)}{.-}")
    local result = string:gsub("\\href{.-}{(.-)}", "\\textcolor{" .. link_color .. "}{%1}")
    return result, link
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
    local strings, types = split_latex_all(text)
    p:deselectAll()
    for i, part in ipairs(strings) do

        --check if part is empty
        if has_real_content(part) then
            part = clean_string(part)
            --group multiple columns together for proper vertical spacing later

            if types[i] == 3 then
                local columns, widths = split_columns_env_with_width(part)
                local xoffset = 0
                local elements = {}
                for j,column in ipairs(columns) do
                    local link = nil
                    column, link = extract_link(column)
                    elements[#elements+1] = ipe.Text({textstyle=styles[types[i]+1], stroke="black",textsize = "normal"}, column, ipe.Vector(left+xoffset,top-i), width*widths[j])
                    xoffset = xoffset +width*widths[j]+skip
                    if link ~= nil then
                        elements[#elements]:setCustom(link)
                    end
                end
                local group = ipe.Group(elements)
                p:insert(nil, group, 2, p:layerOf(prim))
            else
                local link = nil
                part, link = extract_link(part)
                local obj = ipe.Text({textstyle=styles[types[i]+1], stroke="black",textsize = "normal"}, part, ipe.Vector(left,top-i), width)
                if link ~= nil then
                    obj:setCustom(link)
                end
                p:insert(nil, obj , 2, p:layerOf(prim))
            end
        end
    end
    p:remove(prim)
    model:autoRunLatex()
    model:autoRunLatex()

    local selection = model:selection()

    --distribute the created boxed from top to bottom

    local dy = ttb_skip(p,selection)

    for i = 1,#selection do
        local j = selection[i]
        local dy = dy[i]
        if dy ~= 0 then p:transform(j, ipe.Translation(V(0.0, dy))) end
    end

    --ungroup the columns
    local groups = {}
    for i = 1,#selection do
        if p[selection[i]]:type() == "group" then
            groups[#groups + 1] = {selection[i],p[selection[i]]}
        end
    end

    table.sort(groups, function(a,b) 
        i,_ = a
        j,_ = b
        return i > j end)

    for _,group in ipairs(groups) do
        local index = group[1]
        local obj = group[2]
        local elements = obj:elements()
        local matrix = obj:matrix()
        p:remove(index)
        for _,obj in ipairs(elements) do
            p:insert(nil, obj, 2, p:layerOf(prim))
            p:transform(#p, matrix)
        end
    end

    --set links

    selection = model:selection()

    for i = 1,#selection do
        if p[selection[i]]:getCustom() ~= "undefined" then
            local obj = p[selection[i]]
            local link = obj:getCustom()
            print(link)
            local group = ipe.Group({obj})
            group:setText(link)
            p:replace(selection[i],group)
        end
    end 
            
end

-- methods = {
--     { label = "split itemize", run = split},
--   }


---------------------------------------------

shortcuts.ipelet_1_beamer_to_ipe = "Alt+X"