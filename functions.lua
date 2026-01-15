function _G.findIndex(array, target)
    for i, value in ipairs(array) do
        if value == target then
            return i
        end
    end
    return nil 
end

function _G.find_ipelet(name)
	for _, ipelet in pairs(_G.ipelets) do
	   if ipelet.name == name then
		  return(ipelet)
	   end
	end
 end

--functions for parsing the custom tag of objects

custom_delimiter = ":"
empty_string = ":"

function parseCustom(obj)
    local custom = obj:getCustom()
    local result = {}
    for key, value in string.gmatch(custom, '([^=:%s]+)={(.-)}') do
        result[key] = value
    end
    return result
end

function _G.getCustomField(obj, tag)
    local tags = parseCustom(obj)
    for key,value in pairs(tags) do
        if key == tag then return value end
    end
    return nil
end

function newCustomField(obj, tag, content)
    local custom = obj:getCustom()
    if custom == "undefined" or custom == nil or custom == empty_string then
        obj:setCustom(tag .. [[={]] .. content .. [[}]])
    else
        obj:setCustom(obj:getCustom() .. ":" .. tag .. [[={]] .. content .. [[}]])
    end
end

function _G.deleteCustomField(obj,tag) 
    -- Escape magic characters in tag
    tag = tag:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")

    -- Pattern to match tag="...": including the trailing colon
    local pattern = tag .. '={.-}:?'
    
    -- Replace it with an empty string
    local custom = obj:getCustom():gsub(pattern, "")
    if custom == "" then 
        obj:setCustom(empty_string)
    else
        obj:setCustom(custom)
    end
end

function substitute_tag_value(s, tag, content)
    -- Escape magic characters in tag
    tag = tag:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    
    -- Construct pattern and replace
    local pattern = tag .. '={.-}'
    local replacement = tag .. '={' .. content .. '}'
    
    return s:gsub(pattern, replacement)
end

function _G.editCustom(obj, tag, content)
    local custom = _G.getCustomField(obj,tag)
    if custom == nil then 
        newCustomField(obj,tag,content) 
    elseif content == nil then 
        _G.deleteCustomField(obj,tag) 
    else
        tag = tag:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")    
        -- Construct pattern and replace
        local pattern = tag .. '={.-}'
        local replacement = tag .. '={' .. content .. '}'
        obj:setCustom(obj:getCustom():gsub(pattern, replacement))
    end
end

function clean_labels(model)
    local doc = model.doc
    for j = 1, #doc do
        for i, obj, sel, layer in doc[j]:objects() do
            local custom = obj:getCustom()
            if custom == empty_string then 
                local xml = obj:xml():gsub('custom="[^"]*"', 'custom=""', 1)
			    obj = _G.ipe.Object(xml)
                doc[j]:replace(i, obj)
            end
        end
    end
end

function _G.MODEL:custom_backup_runLatex() end
_G.MODEL.custom_backup_runLatex = _G.MODEL.runLatex

function _G.MODEL:runLatex()
   clean_labels(self)
   return self:custom_backup_runLatex()
end

function _G.printTable(tbl)
    for key, value in pairs(tbl) do
        print(key, value)
    end
end