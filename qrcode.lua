label ="qr code"

about = [[Creates a qr code for a given url. Requires the package qrcode to be loaded.]]

function run(model)
    local url = model:getString("Enter url", "Create qr code", nil)
    if not url then return end
    if url:match("^%s*$)") then url = "" end
    obj = ipe.Text({}, "\\qrcode{" .. url .. "}", model.ui:pos())  
    obj:set("transformations", "affine")
    obj = ipe.Group({obj})
    model:creation("create qr code", obj)
    model:autoRunLatex()
    local p = model:page()
    local prim = p:primarySelection()
    p[prim]:setText(url)
end

shortcuts.ipelet_1_qrcode = "Ctrl+Alt+T"