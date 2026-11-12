
label = "Save without timestamp"

about = [[ Saves the document without updating the timestamp to make merging easier. ]]

local auto_export_directory = _G.export_directory

function run(model)
  local fname = model.file_name

  if not fname then
    model:action_save_as()
    return
  end
  
  local fm = _G.formatFromFileName(fname)
  if not fm then
    model:warning("File not saved!",
		 "You must save as *.xml, *.ipe, or *.pdf")
    return
  end

  -- run Latex if format is not XML
  if fm ~= "xml" and not model:runLatex() then
    model.ui:explain("Latex error - file not saved")
    return
  end

  if not model.doc:save(fname, fm, {}, model:imageFolder()) or not model:persistFile(fname) then
    model:warning("File not saved!", "Error saving the document")
    return
  end

  if fm == "xml" and #prefs.auto_export > 0 and config.platform ~= "vscode" then
    model:auto_export(fname)
  end

  model:markAsUnmodified()
  if config.platfrom ~= "vscode" then
    model.ui:explain("Saved document '" .. fname .. "'")
  end
  model.file_name = fname
  model:setCaption()
  model:updateRecentFiles(fname)
  return true
end 

-- function change_auto_export_directory(model) 
--   auto_export_directory = model:getString("Enter directory for auto export")
--   model.ui:explain("set auto export directory to " .. auto_export_directory)
-- end

-- methods = {
--    { label = "Save", run=save },
--    { label = "Change auto export directory", run=change_auto_export_directory },
-- }


--------------

shortcuts.ipelet_1_save_without_timestamps = shortcuts.save
shortcuts.save = nil


-- function _G.MODEL:auto_export(fname)
--   if auto_export_directory == nil then auto_export_directory = "./" end
--   if not self:runLatex() then
--     self.ui:explain("Latex error - could not auto-export!")
--   else
--     for _, format  in ipairs(prefs.auto_export) do
--       local ename = fname:sub(1,-4) .. format
--       ename = auto_export_directory .. string.match(ename, "([^/]+)$")
--       if format == "pdf" then
-- 	      if not self.doc:save(ename, "pdf") then
-- 	        self:warning("Auto-exporting failed",
-- 		       "I could not export in PDF format to file '" .. ename .. "'.")
-- 	      end
--       else
-- 	      self.ui:renderPage(self.doc, 1, 1,
-- 			  format, ename, prefs.auto_export_resolution / 72.0,true, false) -- transparent, nocrop
--       end
--     end
--   end
-- end

function _G.MODEL:auto_export(fname)
  if auto_export_directory == nil then auto_export_directory = "./" end
  if not self:runLatex() then
    self.ui:explain("Latex error - could not auto-export!")
  else
    for _, format  in ipairs(prefs.auto_export) do
      local ename = fname:sub(1,-4) .. format
      ename = auto_export_directory .. string.match(ename, "([^/]+)$")
      if format == "pdf" then
	if not self.doc:save(ename, "pdf", { export=false }, self:imageFolder()) then
	  self:warning("Auto-exporting failed",
		       "I could not export in PDF format to file '" .. ename .. "'.")
	end
      else
	self.ui:renderPage(self.doc, 1, 1,
			   format, ename, prefs.auto_export_resolution / 72.0,
			   true, false) -- transparent, nocrop
      end
      if not self:persistFile(ename) then
	self:warning("Auto-exporting failed",
		     "I could not persist the exported file '" .. ename .. "'.")
      end
    end
  end
end