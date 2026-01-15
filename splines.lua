label = "Spline Offset"

local degree = 3
local n_samples = 100
local V = ipe.Vector
local eps = 0.1

-- Helper: Unit normal to vector (dx, dy)
local function unit_normal(dx, dy)
  local len = math.sqrt(dx*dx + dy*dy)
  if len == 0 then return 0, 0 end
  return -dy / len, dx / len
end

local function offset_3_points(segments,d,n_samples)
   local pts ={}
   local p0 = segments[1]
   local p1 = segments[2]
   local p2 = segments[3]
   local c1 = (p0 + p1*2) * 0.333333333333333
   local c2 = (p1*2 + p2) * 0.333333333333333
   p1=c1
   local p3=p2
   p2=c2

   for j = 0, n_samples do
      local t = j / n_samples
      local u = 1 - t

      -- De Casteljau's formula for Bézier point
      local x = u^3 * p0.x + 3*u^2*t * p1.x + 3*u*t^2 * p2.x + t^3 * p3.x
      local y = u^3 * p0.y + 3*u^2*t * p1.y + 3*u*t^2 * p2.y + t^3 * p3.y

      -- Derivative (tangent)
      local dx = -3*p0.x*u^2 + 3*p1.x*(u^2 - 2*u*t) + 3*p2.x*(2*u*t - t^2) + 3*p3.x*t^2
      local dy = -3*p0.y*u^2 + 3*p1.y*(u^2 - 2*u*t) + 3*p2.y*(2*u*t - t^2) + 3*p3.y*t^2

      local nx, ny = unit_normal(dx, dy)
      table.insert(pts, {x = x + d * nx, y = y + d * ny})
   end
  return pts
end


-- Helper: Sample cubic Bézier segment and compute offset points
local function offset_spline(segments, d, n_samples)
   if #segments == 3 then return offset_3_points(segments,d,n_samples) end

  local pts = {}

  for i = 1, #segments - 3, 1 do
    local p0 = segments[i]
    local p1 = segments[i+1]
    local p2 = segments[i+2]
    local p3 = segments[i+3]

    local point = {x=0,y=0}

      if not p3 then 
         local c1 = (p0 + p1*2) * 0.333333333333333
         local c2 = (p1*2 + p2) * 0.333333333333333
         p1=c1
         p3=p2
         p2=c2
      end

    for j = 0, n_samples do
      local t = j / n_samples
      local u = 1 - t

      -- De Casteljau's formula for Bézier point
      local x = u^3 * p0.x + 3*u^2*t * p1.x + 3*u*t^2 * p2.x + t^3 * p3.x
      local y = u^3 * p0.y + 3*u^2*t * p1.y + 3*u*t^2 * p2.y + t^3 * p3.y

      -- Derivative (tangent)
      local dx = -3*p0.x*u^2 + 3*p1.x*(u^2 - 2*u*t) + 3*p2.x*(2*u*t - t^2) + 3*p3.x*t^2
      local dy = -3*p0.y*u^2 + 3*p1.y*(u^2 - 2*u*t) + 3*p2.y*(2*u*t - t^2) + 3*p3.y*t^2

      local nx, ny = unit_normal(dx, dy)
      table.insert(pts, {x = x + d * nx, y = y + d * ny})
    end
  end
  return pts
end

function uniform_knot_vector(n_ctrl_pts, degree)
  local n_knots = n_ctrl_pts + degree + 1
  local knots = {}
  for i = 1, n_knots do
    if i <= degree + 1 then
      knots[i] = 0
    elseif i >= n_knots - degree then
      knots[i] = 1
    else
      knots[i] = (i - degree - 1) / (n_knots - 2*degree - 1)
    end
  end
  return knots
end

-- Find knot span index
function find_span(n_ctrl_pts, degree, u, knots)
  if u == knots[n_ctrl_pts + 2] then
    return n_ctrl_pts
  end
  for i = degree + 1, n_ctrl_pts + 1 do
    if u >= knots[i] and u < knots[i+1] then
      return i
    end
  end
  return degree + 1
end

-- De Boor’s algorithm for B-spline evaluation
function de_boor(n_ctrl_pts, degree, knots, ctrl_pts, u)
  local k = find_span(n_ctrl_pts, degree, u, knots)
  local d = {}
  for j = 0, degree do
    d[j] = ctrl_pts[k - degree + j]
  end

  for r = 1, degree do
    for j = degree, r, -1 do
      local alpha = (u - knots[k - degree + j]) / (knots[k + 1 + j - r] - knots[k - degree + j])
      d[j] = (1 - alpha) * d[j-1] + alpha * d[j]
    end
  end

  return d[degree]
end

-- Evaluate points on the B-spline curve using de Boor
function evaluate_bspline(ctrl_pts, degree, n_samples)
  local evaluated_pts = {}
  local n_ctrl_pts = #ctrl_pts
  local knots = uniform_knot_vector(n_ctrl_pts, degree)

  for i = 0, n_samples do
    local u = i / n_samples
    local pt = de_boor(n_ctrl_pts, degree, knots, ctrl_pts, u)
    table.insert(evaluated_pts, pt)
  end

  return evaluated_pts
end

function offset_polyline(points, distance)
  local offset_pts = {}

  for i = 1, #points - 1 do
    local p1 = points[i]
    local p2 = points[i+1]
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then len = 1 end  -- avoid degenerate cases
    local nx = -dy / len
    local ny = dx / len

    table.insert(offset_pts, V(p1.x + distance * nx, p1.y + distance * ny))
  end

  -- Offset last point
  local p_last = points[#points]
  local p_prev = points[#points - 1]
  local dx = p_last.x - p_prev.x
  local dy = p_last.y - p_prev.y
  local len = math.sqrt(dx * dx + dy * dy)
  if len == 0 then len = 1 end
  local nx = -dy / len
  local ny = dx / len
  table.insert(offset_pts, V(p_last.x + distance * nx, p_last.y + distance * ny))

  return offset_pts
end



local function make_splinegon(points)
  local segs = { type="closedspline" }
  for i = 1, #points do
    segs[#segs+1] =  ipe.Vector(points[i].x,points[i].y)
  end
  return segs
end


local function make_spline(points)

  local segs = { type="spline" }
  for i = 1, #points do
    segs[#segs+1] =  ipe.Vector(points[i].x,points[i].y)
  end
  local shape = { type="curve", closed=false}
  shape[#shape + 1] = segs
  return shape
end

function getInt(model, string)
   local str
   if ipeui.getString ~= nil then
      str = ipeui.getString(model.ui, string)
   else 
      str = model:getString(string)
   end
   if not str or str:match("^%s*$)") then return 0 end
   return tonumber(str)
end


function offset_single_spline(model, seg, offset, matrix)
   local offset_points = nil
   if #seg < 4 then 
      offset_points = offset_spline(seg,offset,n_samples)
   else 
      local evaluated_points = evaluate_bspline(seg, degree, n_samples)
      offset_points = offset_polyline(evaluated_points, offset)
   end
  local new_path = ipe.Path(model.attributes, {make_spline(offset_points)})
  new_path:setMatrix(matrix)
  model:creation("create arc", new_path)
end

-- Main entry point
function run_offset(model,num)
  local p = model:page()
  local sel = model:selection()
  local prim = p:primarySelection()
  if not prim then
    model:warning("Please select exactly one spline path.")
    return
  end

  local offset = getInt(model, "Enter distance")

  local obj = p[prim]
  if obj:type() ~= "path" then
    model:warning("Selected object is not a path.")
    return
  end

  local shape = obj:shape()[1]

  for _,seg in ipairs(shape) do
    if seg.type == "spline" then
      offset_single_spline(model, seg, offset, obj:matrix()) 
    end
  end

  -- if not shape or #shape ~= 1 then
  --   model:warning("The path must be a single spline.")
  --   return
  -- end

  -- local spline_segments = shape[1][1]
  -- local offset_points = offset_spline(spline_segments, offset, 100)


  -- local new_path = ipe.Path(model.attributes, {methods[num].make(offset_points)})
  -- new_path:setMatrix(obj:matrix())
  -- model:creation("create arc", new_path)
end

function highlight(model, num)
   local p = model:page()
   local prim = p:primarySelection()
   local pobj = p[prim]
   local shape = pobj:shape()[1]

   local pen = make_absolute(model,pobj:get("pen"))
   local dist = (make_absolute(model, model.attributes.pen) + pen) / 2 - eps
   -- offset(model, dist, false)
   for _,seg in ipairs(shape) do
    if seg.type == "spline" then
      offset_single_spline(model, seg, dist, pobj:matrix()) 
    end
  end
end

methods = {
    { label = "offset spline", run=run_offset, make=make_spline},
    { label = "offset splinegon", run=run_offset, make=make_splinegon},
    { label = "highlight edge", run=highlight, make=make_spline},
  }

shortcuts.ipelet_1_splines = "Alt+Shift+S"






function make_absolute(model, pen)
   if _G.type(pen) ~= "number" then 
      local sheets = model.doc:sheets()
      return sheets:find("pen", pen)
   end
   return pen
end











local roundCorners = true

function toggleRoundCorners(model, num)
   roundCorners = not roundCorners
end


function getInt(model, string)
   local str
   if ipeui.getString ~= nil then
      str = ipeui.getString(model.ui, string)
   else 
      str = model:getString(string)
   end
   if not str or str:match("^%s*$)") then return 0 end
   return tonumber(str)
end

-- For each selected path, create the offset path for the given
-- distance.
function offset(model, dist, area)
   p = model:page()
   -- collect segments and build the paths, but do not add them to the
   -- model yet (this would confuse the loop)
   local paths = {}
   for i, obj, sel, layer in p:objects() do
      if sel and obj:type() == "path" then
	 for _, subPath in ipairs(obj:shape()) do
	    -- selected path found -> collect the segments
	    local segments = {}
	    local closed = subPath["closed"]
	    for _, seg in ipairs(subPath) do
	       if (seg["type"] == "segment") then
		  local p1 = obj:matrix() * seg[1]
		  local p2 = obj:matrix() * seg[2]
		  table.insert(segments, {p1, p2})
	       end
	    end
	    -- create the offset curve
	    local curve = offsetCurve(segments, dist, closed)
	    -- create the path
	    local path = nil
	    -- no area -> just add the path
	    if not area then 
	       path = ipe.Path(model.attributes, { curve })
	    end
	    -- area for a closed path -> composition with the original
	    -- curve
	    if area and closed then
	       local origCurve = { type="curve", closed=true }
	       addToCurve(origCurve, segments)
	       path = ipe.Path(model.attributes, { curve, origCurve })
	    end
	    -- area of open path -> concatenate original path with
	    -- offset path
	    if area and not closed then
	       segments[#segments + 1] = {segments[#segments][2], curve[#curve][2]}
	       reverseSegments(segments)
	       addToCurve(curve, segments)
	       curve["closed"] = true
	       path = ipe.Path(model.attributes, { curve })
	    end
	    paths[ #paths + 1 ] = path
	 end
      end
   end
   
   -- actually create paths with the collected curves
   for _, path in ipairs(paths) do
      model:creation("segment created", path)
   end
end

-- Add some segments to a given curve.
function addToCurve(curve, segments)
   for _, seg in ipairs(segments) do
      curve[#curve + 1] = { type="segment", seg[1], seg[2] }
   end
end

-- Reverses the order of a list of segments (and reverses each segment
-- itself).
function reverseSegments(segments)
   local i, j = 1, #segments

   while i < j do
      segments[i], segments[j] = segments[j], segments[i]
      i = i + 1
      j = j - 1
   end

   for _, seg in ipairs(segments) do
      seg[1], seg[2] = seg[2], seg[1]
   end
end

-- Return a curve at distance dist from that path described by the
-- list of points pairs in segments.
function offsetCurve(segs, dist, closed)
   -- add closing segment if curve is closed
   if closed then
      segs[#segs + 1] = {segs[#segs][2], segs[1][1]}
   end
   
   -- shift the segments
   local newSegs = shiftedSegments(segs, dist)

   -- create the curve from the shifted segments
   local curve = { type="curve", closed=closed }
   for i, seg in ipairs(newSegs) do
      -- nicely join consecutive segments
      local next = nextSegment(newSegs, i, closed)
      local arc = joinSegments(seg, next, segs[i][2], dist)
      
      -- add the current segment to the path but skip the first
      -- segment if the curve is closed
      if not (closed and i == 1) then
	 curve[#curve + 1] = { type="segment", seg[1], seg[2] }
      end

      -- create the connecting arc
      if arc then
	 curve[#curve + 1] = arc
      end
   end
   
   -- return the curve
   return curve
end

-- Return a new list of segments obtained by shifting each segment by
-- dist along its normal.
function shiftedSegments(segments, dist)
   local result = {}
   for i, seg in ipairs(segments) do
      local vec = seg[2] - seg[1]
      local norm = vec:orthogonal():normalized()
      result[i] = {seg[1] + dist*norm, seg[2] + dist*norm}
   end
   return result
end

-- Return the next segment after i in a list of segments (modulo is
-- closed is true).
function nextSegment(segments, i, closed)
   local next = segments[i+1]
   if not next and closed then
      next = segments[1]
   end
   return next
end

-- If seg1 and seg2 intersect, they are shortened such that the
-- endpoint of seg1 coincides with the endpoint of seg2.  Otherwise,
-- an arc (with given center and radius) joining the endpoint of seg1
-- with the startpoint of seg2 is returned.  The sign of radius
-- indicates whether the arc goes clockwise or counterclockwise.
function joinSegments(seg1, seg2, center, radius)
   -- return nil if one of the segments is nil
   if not seg1 or not seg2 then return nil end

   -- lengthen both segments if the tarnsition should be sharp
   if not roundCorners then
      local p1 = seg1[2]
      local p2 = seg1[1]
      local pDelta = p1 - p2
      local pNorm = pDelta:normalized()
      local newP1 =  p1 + pNorm * 500
      seg1[2] = newP1

      local q1 = seg2[1]
      local q2 = seg2[2]
      local qDelta = q1 - q2
      local qNorm = qDelta:normalized()
      local newQ1 =  q1 + qNorm * 500
      seg2[1] = newQ1
   end
   
   -- shorten to intersection (and stop if there is one)
   local intersection = shortenToIntersection(seg1, seg2)
   if intersection then return nil end
   
   -- create the arc
   local m1 = nil
   if radius > 0 then
      m1 = ipe.Matrix(radius, 0, 0, -radius)
   else
      m1 = ipe.Matrix(radius, 0, 0, radius)
   end
   local m2 = ipe.Translation(center)
   local myArc = ipe.Arc(m2*m1, seg2[1], seg1[2])
   return { type="arc", arc=myArc, seg1[2], seg2[1]}
end

-- Shorten the segments to their intersection (if exists) such that
-- the endpoint of seg1 coincides with the startpoint of seg2.  The
-- intersection is returned (nil if there is no intersection).
function shortenToIntersection(seg1, seg2)
   local intersection = nil
   -- create ipe segments
   seg1Ipe = ipe.Segment(seg1[1], seg1[2])
   seg2Ipe = ipe.Segment(seg2[1], seg2[2])
   intersection = seg1Ipe:intersects(seg2Ipe)
   if intersection then 
      -- shorten segments to meet at their intersection
      seg1[2] = intersection
      seg2[1] = intersection
   end
   return intersection
end

-- some debug output to figure out how arcs exactly work
function test(model, num)
   p = model:page()
   local write = _G.io.write
   local segments = {}
   for i, obj, sel, layer in p:objects() do
      if sel and obj:type() == "path" then
	 write("path:\n")
	 for _, subPath in ipairs(obj:shape()) do
	    write("subpath: ")
	    write(subPath["type"])
	    write("\n")
	    for _, seg in ipairs(subPath) do
	       write("segment: ")
	       write(seg["type"])
	       write("\n")
	       for key, val in pairs(seg) do
		  write(key)
		  write(" -> ")
		  print(val)
	       end
	       if seg["type"] == "arc" then
		  local arc = seg["arc"]
		  write("arc endpoints: ")
		  print(arc:endpoints())
		  write("arc matrix: ")
		  print(arc:matrix())
		  write("arc angles: ")
		  print(arc:angles())
	       end
	       write("\n")
	    end
	 end
      end
   end
end