label = "annotate"

function get_pdf_page_count(file_path)
    local handle = _G.io.popen('pdfinfo "' .. file_path .. '"')
    if not handle then return nil end

    local result = handle:read("*a")
    handle:close()

    for line in result:gmatch("[^\r\n]+") do
        local key, value = line:match("^(.-):%s*(.+)$")
        if key == "Pages" then
            return tonumber(value)
        end
    end

    return nil
end 

function get_first_page_size(file_path)
    local handle = _G.io.popen('pdfinfo -box "' .. file_path .. '"')
    if not handle then return nil end

    local output = handle:read("*a")
    handle:close()

    local width, height = output:match("Page size:%s+([%d%.]+)%s+x%s+([%d%.]+)%s+pts")
    if width and height then
        return tonumber(width), tonumber(height)
    end

    return nil, nil
end

function run(model)
    local filter_save = {"PDF (*.pdf)", "*.pdf" }
    local file,_ = ipeui.fileDialog(nil, "open", "Choose the file to annotate", filter_save, nil, nil, 1)

    if file == nil then return end
    local width,height = get_first_page_size(file)
    local layout = [[<ipestyle name="layout"><layout paper="]] .. width .. " " .. height .. [[" origin="0 0" frame="]] .. width .. " " .. height ..[["/></ipestyle>]]
    local sheet = ipe.Sheet(nil, layout)

    local pages = get_pdf_page_count(file)

    local doc = model.doc
    local sheets = doc:sheets()
    sheets:insert(1,sheet)
    if #doc[#doc] == 0 then
        doc:remove(#doc)
    end
    for i = 1,pages do 
        local p = _G.ipe.Page() 
        p:addLayer("pdf")
        p:setVisible(1,"pdf",true)
        p:setLocked("pdf",true)
        local xml = [[<text pos="0 0">\includegraphics[page=]] .. i .. ']{' .. file ..'}</text>'
        local obj = _G.ipe.Object(xml)
        p:insert(nil,obj,nil,"pdf")
        doc:append(p)
    end

    model.snap.grid_visible = false
    model.snap.snapgrid = false
    model.snap.snapauto =true
    model:setSnap()
    model.ui:update()
    local a = model.attributes
    a.stroke = "signalblue1"
    a.pen = "ultrafat"
     model.ui:setAttributes(model.doc:sheets(), a)
    model.ui:update()
    model:setPage()
    model:autoRunLatex()
end

shortcuts.ipelet_1_annotate = "Ctrl+Alt+O"