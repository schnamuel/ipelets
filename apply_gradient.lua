
label = "Arrow stroke gradients"
about = "Apply coordinate-named stroke gradients to arrow paths."

local PREFIX = "arrow_gradient_"
local STYLE_NAME = "GeneratedArrowGradients"

local function has_arrow(obj, attr)
  local v = obj:get(attr)
  return v == true or v == "true"
end

local function endpoints(obj)
  local shape = obj:shape()
  if #shape ~= 1 then return nil end

  local curve = shape[1]
  if curve.type ~= "curve" or curve.closed or #curve == 0 then
    return nil
  end

  local first = curve[1]
  local last = curve[#curve]
  local single_straight_segment = #curve == 1 and first.type == "segment"
  return first[1], last[#last], single_straight_segment
end

local function xml_escape(s)
  return tostring(s)
    :gsub("&", "&amp;")
    :gsub('"', "&quot;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
end

local function coordinate_part(n)
  return string.format("%.12g", n)
    :gsub("%-", "m")
    :gsub("%+", "")
    :gsub("%.", "p")
end

local function gradient_name(p, q)
  return PREFIX ..
    "x" .. coordinate_part(p.x) ..
    "_y" .. coordinate_part(p.y) ..
    "_x" .. coordinate_part(q.x) ..
    "_y" .. coordinate_part(q.y)
end

local function gradient_xml(name, c1, c2, p, q, hard)
  local stops

  if hard then
    stops = string.format(
      '<stop offset="0" color="%s"/>\n' ..
      '<stop offset="0.4" color="%s"/>\n' ..
      '<stop offset="0.6" color="%s"/>\n' ..
      '<stop offset="1" color="%s"/>',
      c1, c1, c2, c2
    )
  else
    stops = string.format(
      '<stop offset="0" color="%s"/>\n' ..
      '<stop offset="1" color="%s"/>',
      c1, c2
    )
  end

  return string.format(
    '<gradient name="%s" type="axial" extend="yes" ' ..
    'coords="%.12g %.12g %.12g %.12g">\n%s\n</gradient>',
    xml_escape(name), p.x, p.y, q.x, q.y, stops
  )
end

local function color_names(sheets)
  local names = sheets:allNames("color")
  table.sort(names)
  return names
end

local function resolve_color(sheets, name)
  if name == "black" then return "0 0 0" end
  if name == "white" then return "1 1 1" end

  local c = sheets:find("color", name)
  if not c or c.r == nil or c.g == nil or c.b == nil then
    return nil
  end

  return string.format("%.12g %.12g %.12g", c.r, c.g, c.b)
end

local function ask_options(model, colors)
  local d = ipeui.Dialog(model.ui:win(), "Arrow Stroke Gradients")

  d:add("startcolor", "combo", colors, 1, 1, 1, 2)
  d:add("endcolor", "combo", colors, 2, 1, 1, 2)
  d:add("hard", "checkbox",
    { label = "Rapid color change at midpoint" }, 3, 1, 1, 2)

  d:addButton("ok", "&Apply", "accept")
  d:addButton("cancel", "&Cancel", "reject")

  d:set("startcolor", 1)
  d:set("endcolor", #colors)
  d:set("hard", false)

  if not d:execute() then return nil end

  local a = d:get("startcolor")
  local b = d:get("endcolor")
  if not a or not b then return nil end

  return colors[a], colors[b], d:get("hard")
end

local function find_gradient_sheet(sheets)
  for i = 1, sheets:count() do
    local s = sheets:sheet(i)
    if s:name() == STYLE_NAME then
      return i, s
    end
  end
  return nil, nil
end

local function make_sheet(definitions)
  local names = {}
  for name in pairs(definitions) do
    names[#names + 1] = name
  end
  table.sort(names)

  local parts = {}
  for _, name in ipairs(names) do
    parts[#parts + 1] = definitions[name]
  end

  local xml =
    '<ipestyle name="' .. STYLE_NAME .. '">\n' ..
    table.concat(parts, "\n") ..
    '\n</ipestyle>'

  return ipe.Sheet(nil, xml)
end

local function updated_sheets(sheets, definitions)
  local index, existing = find_gradient_sheet(sheets)
  local target

  if existing then
    target = existing:clone()
  else
    target = ipe.Sheet()
    target:setName(STYLE_NAME)
  end

  local generated = make_sheet(definitions)

  for name in pairs(definitions) do
    target:remove("gradient", name)
    target:addFrom(generated, "gradient", name)
  end

  local updated = sheets:clone()

  if index then
    updated:remove(index)
    updated:insert(index, target)
  else
    updated:insert(1, target)
  end

  return updated
end

local function process_page(page, c1, c2, hard, definitions)
  local newpage = page:clone()
  local changed, skipped = 0, 0

  for i, obj in page:objects() do
    if obj:type() == "path" and
       (has_arrow(obj, "farrow") or has_arrow(obj, "rarrow")) then

      local p, q, single_segment = endpoints(obj)

      if p and q then
        if has_arrow(obj, "rarrow") and
           not has_arrow(obj, "farrow") then
          p, q = q, p
        end

        local name = gradient_name(p, q)
        definitions[name] = gradient_xml(name, c1, c2, p, q, hard)

        newpage:setAttribute(i, "strokegradient", name)
        -- newpage:setAttribute(i, "gradient", name)
        if single_segment then
          newpage:setAttribute(i, "pathmode", "strokedfilled")
        end
        changed = changed + 1
      else
        skipped = skipped + 1
      end
    end
  end

  return newpage, changed, skipped
end

local function apply_gradients(model, all_pages)
  local doc = model.doc
  local sheets = doc:sheets()
  local colors = color_names(sheets)

  if #colors == 0 then
    model:warning("Arrow gradients", "No named colors are available.")
    return
  end

  local start_name, end_name, hard = ask_options(model, colors)
  if not start_name then return end

  local c1 = resolve_color(sheets, start_name)
  local c2 = resolve_color(sheets, end_name)

  if not c1 or not c2 then
    model:warning("Arrow gradients", "Could not resolve the selected colors.")
    return
  end

  local definitions = {}
  local changed, skipped = 0, 0
  local changed_pages = {}
  local page_numbers = {}

  if all_pages then
    for pno = 1, #doc do
      page_numbers[#page_numbers + 1] = pno
    end
  else
    page_numbers[1] = model.pno
  end

  for _, pno in ipairs(page_numbers) do
    local page = doc[pno]
    if page then
      local newpage, page_changed, page_skipped =
        process_page(page, c1, c2, hard, definitions)
      changed = changed + page_changed
      skipped = skipped + page_skipped
      if page_changed > 0 then
        changed_pages[#changed_pages + 1] = {
          pno = pno,
          oldpage = page:clone(),
          newpage = newpage,
        }
      end
    end
  end

  if changed == 0 then
    model:warning(
      "Arrow gradients",
      "No eligible open arrow paths were found.\nSkipped: " .. skipped
    )
    return
  end

  local old_sheets = sheets:clone()
  local new_sheets = updated_sheets(sheets, definitions)
  local action = {
    label = all_pages and "Apply arrow stroke gradients to all pages" or
      "Apply arrow stroke gradients",
    pno = model.pno,
    pages = changed_pages,
    old_sheets = old_sheets,
    new_sheets = new_sheets,
    style_sheets_changed = true,
  }

  function action:undo(document)
    document:replaceSheets(self.old_sheets:clone())
    for _, entry in ipairs(self.pages) do
      document:set(entry.pno, entry.oldpage:clone())
    end
  end

  function action:redo(document)
    document:replaceSheets(self.new_sheets:clone())
    for _, entry in ipairs(self.pages) do
      document:set(entry.pno, entry.newpage:clone())
    end
  end

  model:register(action)
end

local function run(model)
  apply_gradients(model, false)
end

local function run_all(model)
  apply_gradients(model, true)
end

methods = {
  { label = "Current page", run = run },
  { label = "All pages", run = run_all },
}
