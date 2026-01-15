 label = "grayscale"

function rgb_to_grayscale(color)
    local gray = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
    return {r=gray, g=gray, b=gray}
end

function check_color(sheets, obj, attribute)
    local val = obj:get(attribute)
    val = sheets:find("color", val)
    obj:set(attribute, rgb_to_grayscale(val)) 
end

function run(model)
    local doc = model.doc
    local sheets = model.doc:sheets()

    for j =1,#doc do
        local p = doc[j]
        for i, obj, _ , _  in p:objects() do
            if obj:type() ~= "group" then
                check_color(sheets, obj, "stroke")
                check_color(sheets, obj, "fill")
            end
        end
    end
end