function _G.MODEL:layeraction_delete(layer)
  local p = self:page()
  local layers = p:layers()
  local backup_layer = nil
  for _,l in pairs(layers) do
    if l ~= layer and not p:isLocked(l) then
        backup_layer = l
        break
    end
  end
  print(backup_layer)
  for j = 1, p:countViews() do
    if layer == p:active(j) then
        if backup_layer == nil then 
      self:warning("Cannot delete layer '" .. layer .. "'.",
		   "Layer '" .. layer .. "' is the active layer of view "
		     .. j .. ".")
      return
        else 
            p:setActive(j,backup_layer)
        end
    end
  end
  local t = { label="delete layer " .. layer,
	      pno=self.pno,
	      vno=self.vno,
	      original=p:clone(),
	      layer=layer,
	      undo=revertOriginal
	    }
  t.redo = function (t, doc)
	     local p = doc[t.pno]
	     for i = #p,1,-1 do
	       if p:layerOf(i) == t.layer then
		 p:remove(i)
	       end
	     end
	     p:removeLayer(t.layer)
	   end
  self:register(t)
end 