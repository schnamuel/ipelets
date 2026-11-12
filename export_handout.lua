label = "Export Marked Views"
about = "Export marked views of marked pages to PDF."

function run(model)

  local src = model.doc
  local dst = ipe.Document()
  dst:setProperties(src:properties())
  dst:remove(1)
  dst:replaceSheets(src:sheets():clone())
  
  -- Copy only marked views from marked pages.
  for pno, page in src:pages() do

    if page:marked() then

      local newpage = page:clone()
      local keep = {}
      local nmarked = 0

      -- Find marked views.
      for v = 1, page:countViews() do
        if page:markedView(v) then
          keep[v] = true
          nmarked = nmarked + 1
        end
      end

      -- If no view is marked, keep the last view.
      if nmarked == 0 then
        keep[page:countViews()] = true
      end

      -- Remove all other views.
      for v = newpage:countViews(), 1, -1 do
        if not keep[v] then
          newpage:removeView(v)
        end
      end

      dst:append(newpage)
    end
  end

  if #dst == 0 then
    model:warning(
      "No marked pages",
      "No marked pages were found."
    )
    return
  end

  -- Ask the user for the PDF filename.
  local filename = ipeui.fileDialog(
    model.ui:win(),
    "save",
    "Export marked views",
    {
      "PDF (*.pdf)", "*.pdf"
    },
    nil,
    nil,
    1
  )

  if not filename then
    return
  end

  dst:runLatex(nil)

  if not filename:match("%.pdf$") then
    filename =  filename .. ".pdf"
  end

  if not dst:save(filename, "pdf", {}, model:imageFolder()) then
    model:warning("File not saved!", "Error saving the document")
    return
  end

  -- -- Write the new document directly as PDF.
  -- local ok, err = dst:save(
  --   filename,
  --   "pdf",
  --   { export = true }
  -- )

  -- if not ok then
  --   model:warning(
  --     "Could not save PDF",
  --     tostring(err)
  --   )
  --   return
  -- end

  model.ui:explain("Exported marked views to " .. filename)
end
