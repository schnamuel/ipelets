label = "List shortcuts" 

--this is a map for the names of the shortcuts
local name_map = {
    ["new_window"] = "New Window",
    ["new"] = "New",
    ["open"] = "Open",
    ["save"] = "Save",
    ["download"] = "Download",
    ["save_as"] = "Save as",
    ["manage_files"] = "Manage files",
    ["export_png"] = "Export as PNG",
    ["export_eps"] = "Export as EPS",
    ["export_svg"] = "Export as SVG",
    ["insert_image"] = "Insert image",
    ["auto_latex"] = "Automatically run Latex",
    ["run_latex"] = "Run Latex",
    ["document_properties"] = "Document properties",
    ["add_style_sheets"] = "Add style sheets",
    ["style_sheets"] = "Style sheets",
    ["update_style_sheets"] = "Update style sheets",
    ["check_style"] = "Check symbolic attributes",
    ["close"] = "Close",
    ["undo"] = "Undo",
    ["redo"] = "Redo",
    ["cut"] = "Cut",
    ["copy"] = "Copy",
    ["paste"] = "Paste",
    ["paste_with_layer"] = "Paste with layer",
    ["paste_at_cursor"] = "Paste at cursor",
    ["delete"] = "Delete",
    ["group"] = "Group",
    ["ungroup"] = "Ungroup",
    ["front"] = "Front",
    ["back"] = "Back",
    ["forward"] = "Forward",
    ["backward"] = "Backward",
    ["before"] = "Just before",
    ["behind"] = "Just behind",
    ["duplicate"] = "Duplicate",
    ["select_all"] = "Select all",
    ["deselect_all"] = "Deselect all",
    ["pick_properties"] = "Pick properties",
    ["apply_properties"] = "Apply properties",
    ["insert_text_box"] = "Insert text box",
    ["change_width"] = "Change text width",
    ["edit"] = "Edit object",
    ["edit_as_xml"] = "Edit object as XML",
    ["edit_group"] = "Edit group",
    ["end_group_edit"] = "End group edit",
    ["mode_select"] = "Select objects",
    ["mode_translate"] = "Translate objects",
    ["mode_rotate"] = "Rotate objects",
    ["mode_stretch"] = "Stretch objects",
    ["mode_shear"] = "Shear objects",
    ["mode_graph"] = "Move graph nodes",
    ["mode_pan"] = "Pan the canvas",
    ["mode_shredder"] = "Shred objects",
    ["mode_laser"] = "Laser pointer",
    ["mode_label"] = "Text labels",
    ["mode_math"] = "Mathematical symbols",
    ["mode_paragraph"] = "Paragraphs",
    ["mode_marks"] = "Marks",
    ["mode_rectangles1"] = "Axis-parallel rectangles",
    ["mode_rectangles3"] = "Rectangles",
    ["mode_parallelogram"] = "Parallelograms",
    ["mode_lines"] = "Lines and polylines",
    ["mode_polygons"] = "Polygons",
    ["mode_splines"] = "Splines",
    ["mode_splinegons"] = "Splinegons",
    ["mode_arc1"] = "Circular arcs (by center, right and left point)",
    ["mode_arc2"] = "Circular arcs (by center, left and right point)",
    ["mode_arc3"] = "Circular arcs (by 3 points)",
    ["mode_circle1"] = "Circles (by center and radius)",
    ["mode_circle2"] = "Circles (by diameter)",
    ["mode_circle3"] = "Circles (by 3 points)",
    ["mode_ink"] = "Ink",
    ["snapvtx"] = "Snap to vertex",
    ["snapctl"] = "Snap to control point",
    ["snapbd"] = "Snap to boundary",
    ["snapint"] = "Snap to intersection",
    ["snapgrid"] = "Snap to grid",
    ["snapcustom"] = "Snap to custom grid",
    ["snapangle"] = "Angular snap",
    ["snapauto"] = "Automatic snap",
    ["set_origin"] = "Set origin",
    ["set_origin_snap"] = "Set origin & snap",
    ["show_axes"] = "Show axes",
    ["set_direction"] = "Set direction",
    ["set_tangent_direction"] = "Set tangent direction",
    ["reset_direction"] = "Reset direction",
    ["set_line"] = "Set line",
    ["set_line_snap"] = "Set line & snap",
    ["fullscreen"] = "Fullscreen",
    ["grid_visible"] = "Grid visible",
    ["pretty_display"] = "Pretty display",
    ["zoom_in"] = "Zoom in",
    ["zoom_out"] = "Zoom out",
    ["normal_size"] = "Normal size",
    ["fit_page"] = "Fit page",
    ["fit_width"] = "Fit width",
    ["fit_top"] = "Fit page top",
    ["fit_objects"] = "Fit objects",
    ["fit_selection"] = "Fit selection",
    ["pan_here"] = "Pan here",
    ["new_layer"] = "New layer",
    ["new_layer_view"] = "New layer, new view",
    ["rename_active_layer"] = "Rename active layer",
    ["select_in_active_layer"] = "Select all in active  layer",
    ["move_to_active_layer"] = "Move to active layer",
    ["next_view"] = "Next view",
    ["previous_view"] = "Previous view",
    ["first_view"] = "First view",
    ["last_view"] = "Last view",
    ["new_view"] = "New view",
    ["delete_view"] = "Delete view",
    ["mark_from_view"] = "Mark views from this view",
    ["unmark_from_view"] = "Unmark views from this view",
    ["jump_view"] = "Jump to view",
    ["edit_view"] = "Edit view",
    ["view_sorter"] = "View sorter",
    ["next_page"] = "Next page",
    ["previous_page"] = "Previous page",
    ["first_page"] = "First page",
    ["last_page"] = "Last page",
    ["new_page"] = "New page",
    ["cut_page"] = "Cut page",
    ["copy_page"] = "Copy page",
    ["paste_page"] = "Paste page",
    ["delete_page"] = "Delete page",
    ["jump_page"] = "Jump to page",
    ["edit_title"] = "Edit title & sections",
    ["edit_notes"] = "Edit notes",
    ["page_sorter"] = "Page sorter",
    ["toggle_notes"] = "Notes",
    ["toggle_bookmarks"] = "Bookmarks",
    ["manual"] = "Ipe manual",
    ["finger_draw"] = "Draw with finger",
    ["tablet_hints"] = "Hints for tablet users",
    ["preferences"] = "Preferences",
    ["keyboard"] = "Onscreen keyboard",
    ["show_configuration"] = "Show &configuration",
    ["show_libraries"] = "Show &libraries",
    ["about_ipelets"] = "&Ipelet information",
    ["cloud_latex"] = "Enable online Latex-compilation",
    ["developer_reload_ipelets"] = "Reload ipelets",
    ["developer_list_shortcuts"] = "List shortcuts",
}

function find_ipelet(name)
	for _, ipelet in pairs(_G.ipelets) do
	   if ipelet.name == name then
		  return(ipelet)
	   end
	end
 end

local button = false

local saved_shortcuts_by_key = {}
local saved_shortcuts = {}
local by_key = false

function print_on_terminal(d)
    button = true
    d:accept()
end

function sort_by_shortcut(d)
    if by_key then 
        d:set("list",saved_shortcuts)
        by_key = false
    else
        d:set("list",saved_shortcuts_by_key)
        by_key = true
    end

end

function run(model)
    saved_shortcuts = {}
    saved_shortcuts_by_name = {}
    for label, shortcut in pairs(_G.shortcuts) do
        local name = label
        if string.find(name, "ipelet_") then
            name = name:gsub("^ipelet_%d+_", "")
            local ipelet = find_ipelet(name)
            if ipelet ~= nil then 
                if ipelet.label ~= nil then
                    name = ipelet.label
                end
                if ipelet.methods ~= nil then
                    local number = tonumber(label:gsub("%D", ""))
                    if ipelet.methods[number] ~= nil then
                        name = "(" .. name ..  ") " .. ipelet.methods[number].label
                    end
                end
            end
        else
            if name_map[name] then 
              name = name_map[name] 
            end
        end
        name = name:gsub("&&", "&")
        shortcut = shortcut:gsub("+", " + ")
        saved_shortcuts[#saved_shortcuts + 1] = name .. ": '" .. shortcut .."' (shortcuts." .. label .. ")\n"
        saved_shortcuts_by_key[#saved_shortcuts_by_key + 1] = "'" .. shortcut .. "': " .. name .. " (shortcuts." .. label .. ")\n"
    end

    table.sort(saved_shortcuts)
    table.sort(saved_shortcuts_by_key, function(a, b)
  local akey = a:match("'(.-)'")
  local bkey = b:match("'(.-)'")
  return akey < bkey
end)


    local s = table.concat(saved_shortcuts, "\n")
    s = s:gsub("\n$", "")

    d = ipeui.Dialog(win, "Shortcuts")
    d:add("list", "list", {}, 2, 1)
    d:set("list", saved_shortcuts)
    d:addButton("ok", "Ok", "accept")
    d:addButton("sort", "Change sorting", sort_by_shortcut)
    d:addButton("copy", "Copy to clipboard", "reject")
    d:addButton("print", "Print on terminal", print_on_terminal)
    copy = d:execute(prefs.latexlog_size)
    if not copy then model.ui:setClipboard(s) end
    if button then 
        print(s)
        button = false
    end
end

------------------------------------------

shortcuts.ipelet_1_list_shortcuts = "H"