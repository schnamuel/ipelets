----------------------------------------------------------------------
-- goodies ipelet
----------------------------------------------------------------------
--[[

    This file is part of the extensible drawing editor Ipe.
    Copyright (c) 1993-2024 Otfried Cheong

    Ipe is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    As a special exception, you have permission to link Ipe with the
    CGAL library and distribute executables, as long as you follow the
    requirements of the Gnu General Public License in regard to all of
    the software in the executable aside from CGAL.

    Ipe is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with Ipe; if not, you can find it at
    "http://www.gnu.org/copyleft/gpl.html", or write to the Free
    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

--]]

label = "My Goodies"

revertOriginal = _G.revertOriginal

about = [[
Slight adjustments to the ipe native "Goodies" ipelet
Regular n-gon rotates the polygon such that one sight is parallel to the x-axis.
The other functions all use the center of each singular object for the transformation instead of the center of the union of the objects.
]]

V = ipe.Vector

function preciseTransform(model, num)
  local p = model:page()
  if not p:hasSelection() then
    model.ui:explain("no selection")
    return
  end

  if (num==3 or num==4) and not model.snap.with_axes then
    model:warning("Cannot mirror at axis", "The coordinate system has not been set")
    return
  end

  -- check pinned
  for i, obj, sel, layer in p:objects() do
    if sel and obj:get("pinned") ~= "none" then
      model:warning("Cannot transform objects",
		    "At least one of the objects is pinned")
      return
    end
  end

  local matrix
  local label = methods[num].label
  if num == 1 then  -- mirror horizontal
    matrix = ipe.Matrix(-1, 0, 0, 1, 0, 0)
  elseif num == 2 then -- Mirror vertical
    matrix = ipe.Matrix(1, 0, 0, -1, 0, 0)
  elseif num == 3 then -- Mirror at x-axis
    matrix = (ipe.Rotation(model.snap.orientation)
	    * ipe.Matrix(1, 0, 0, -1, 0, 0)
	  * ipe.Rotation(-model.snap.orientation))
  elseif num == 4 then -- Mirror at y-axis
    matrix = (ipe.Rotation(model.snap.orientation)
	    * ipe.Matrix(-1, 0, 0, 1, 0, 0)
	  * ipe.Rotation(-model.snap.orientation))
  elseif num == 5 then   -- turn 90 degrees
    matrix = ipe.Matrix(0, 1, -1, 0, 0, 0)
  elseif num == 6 then   -- turn 180 degrees
    matrix = ipe.Matrix(-1, 0, 0, -1, 0, 0)
  elseif num == 7 then   -- turn 270 degrees
    matrix = ipe.Matrix(0, -1, 1, 0, 0, 0)
  elseif num == 8 then   -- rotate by angle
    local str = model:getString("Enter angle in degrees")
    if not str or str:match("^%s*$") then return end
    local degrees = tonumber(str)
    if not degrees then
      model:warning("Please enter angle in degrees")
      return
    end
    matrix = ipe.Rotation(math.pi * degrees / 180.0)
    label = "rotation by " .. degrees .. " degrees"
  elseif num == 9 then   -- stretch or scale
    local str = model:getString("Enter stretch factors")
    if not str or str:match("^%s*$") then return end
    if str:match("^[%+%-%d%.]+$") then
      local sx = tonumber(str)
      if sx == 0 then
	model:warning("Illegal scale factor",
		      "You cannot use a zero scale factor")
	return
      end
      label = "scale by " .. sx
      matrix = ipe.Matrix(sx, 0, 0, sx, 0, 0)
    else
      local ssx, ssy = str:match("^([%+%-%d%.]+)%s+([%+%-%d%.]+)$")
      if not ssx then
	model:warning("Please enter numeric stretch factors",
		      "You can either enter a single number to scale the object"
			.. " or two numbers to stretch in x and y directions.")
	return
      end
      local sx, sy = tonumber(ssx), tonumber(ssy)
      if sx == 0 or sy == 0 then
	model:warning("Illegal stretch factor",
		      "You cannot use a zero stretch factor")
	return
      end
      label = "stretch by " .. sx .. ", " .. sy
      matrix = ipe.Matrix(sx, 0, 0, sy, 0, 0)
    end
    if model.snap.with_axes then
      matrix = (ipe.Rotation(model.snap.orientation)
	      * matrix
	      * ipe.Rotation(-model.snap.orientation))
    end
  end

  local matrix_list = {}
  local selection = model:selection()
  for _,i in ipairs(selection) do
    local box = p:bbox(i)
    local origin = 0.5 * (box:bottomLeft() + box:topRight())
    matrix_list[#matrix_list + 1] = ipe.Translation(origin) * matrix * ipe.Translation(-origin)
  end

  local t = { label = label,
	      pno = model.pno,
	      vno = model.vno,
	      selection = model:selection(),
	      original = model:page():clone(),
	      matrix_list = matrix_list,
	      undo = revertOriginal,
	    }
  t.redo = function (t, doc)
	     local p = doc[t.pno]
	     for number,i in ipairs(t.selection) do p:transform(i, t.matrix_list[number]) end
	   end
  model:register(t)
end

function checkPrimaryIsCircle(model, arc_ok)
  local p = model:page()
  local prim = p:primarySelection()
  if not prim then model.ui:explain("no selection") return end
  local obj = p[prim]
  if obj:type() == "path" then
    local shape = obj:shape()
    if #shape == 1 then
      local s = shape[1]
      if s.type == "ellipse" then
	return prim, obj, s[1]:translation(), shape
      end
      if arc_ok and s.type == "curve" and #s == 1 and s[1].type == "arc" then
	return prim, obj, s[1].arc:matrix():translation(), shape
      end
    end
  end
  if arc_ok then
    model:warning("Primary selection is not an arc, a circle, or an ellipse")
  else
    model:warning("Primary selection is not a circle or an ellipse")
  end
end



function ngon(model)
  local prim, obj, pos, shape = checkPrimaryIsCircle(model, false)
  if not prim then return end

  local str = model:getString("Enter number of corners")
  if not str or str:match("^%s*$)") then return end
  local k = tonumber(str)
  if not k then
    model:warning("Enter a number between 3 and 1000!")
    return
  end

  local m = shape[1][1]
  local center = m:translation()
  local v = m * V(1,0)
  local radius = (v - center):len()

  local curve = { type="curve", closed=true }
  local alpha = 2 * math.pi / k
  local offset = (math.pi + ((k + 1) % 2) * alpha) / 2

  local v0 = center + radius * ipe.Direction(offset)

  for i = 1,k-1 do
    local v1 = center + radius * ipe.Direction(i * alpha + offset)
    curve[#curve + 1] = { type="segment", v0, v1 }
    v0 = v1
  end

  local kgon = ipe.Path(model.attributes, { curve } )
  kgon:setMatrix(obj:matrix())
  model:creation("create regular k-gon", kgon)
end


methods = {
  { label = "Mirror horizontal", run=preciseTransform },
  { label = "Mirror vertical", run=preciseTransform },
  { label = "Mirror at x-axis", run=preciseTransform },
  { label = "Mirror at y-axis", run=preciseTransform },
  { label = "Turn 90 degrees", run=preciseTransform },
  { label = "Turn 180 degrees", run=preciseTransform },
  { label = "Turn 270 degrees", run=preciseTransform },
  { label = "Precise rotate", run=preciseTransform },
  { label = "Precise stretch", run=preciseTransform },
  { label = "Regular n-Gon", run=ngon },
}

----------------------------------------------------------------------
shortcuts.ipelet_10_my_goodies = "n"