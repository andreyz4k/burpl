
export ObjectPrior
module ObjectPrior

using burpl: OInt

struct Object
    shape::Array{OInt,2}
    position::Tuple{OInt,OInt}
end

Object(a::Array{OInt,1}, pos::Tuple{OInt,OInt}) = Object(hcat(a), pos)

Base.:(==)(a::Object, b::Object) = a.shape == b.shape && a.position == b.position
Base.hash(obj::Object, h::UInt64) = hash(obj.shape, h) + hash(obj.position, h)

Base.show(io::IO, obj::Object) = print(io, "Object(", obj.shape, ", ", obj.position, ")")

struct Color
    value::OInt
end

Base.:(==)(a::Color, b::Color) = a.value == b.value

Base.hash(c::Color, h::UInt64) = hash(c.value, h)
Base.show(io::IO, c::Color) = print(io, "Color(", c.value, ")")

get_color(obj::Object) = Color(maximum(obj.shape))

function candidates(i, j, grid)
    res = []
    if j > 1
        push!(res, (i, j - 1))
    end
    if i > 1
        push!(res, (i - 1, j))
    end
    if j < size(grid)[2]
        push!(res, (i, j + 1))
    end
    if i < size(grid)[1]
        push!(res, (i + 1, j))
    end
    return res
end

function find_component(grid, i, j, visited)
    queue = []
    push!(queue, (i, j))
    component = []
    while !isempty(queue)
        point = popfirst!(queue)
        if in(point, visited)
            continue
        end
        push!(visited, point)
        push!(component, point)

        for cand_point in candidates(point[1], point[2], grid)
            if !in(cand_point, visited) && grid[point...] == grid[cand_point...]
                push!(queue, cand_point)
            end
        end
    end
    return component
end

function normalize_component(points, grid)
    minx, maxx = extrema((p[1] for p in points))
    miny, maxy = extrema((p[2] for p in points))
    component = fill(OInt(-1), maxx - minx + 1, maxy - miny + 1)
    for p in points
        component[p[1]-minx+1, p[2]-miny+1] = grid[p...]
    end
    (minx, miny), component
end

function find_objects(grid::Array{OInt,2})
    objects = Set{Object}()

    visited = Set()
    s = size(grid)

    for i = 1:s[1], j = 1:s[2]
        if grid[i, j] != OInt(-1) && !in((i, j), visited)
            points = find_component(grid, i, j, visited)
            position, component = normalize_component(points, grid)
            push!(objects, Object(component, position))
        end
    end

    return objects
end

point_in_rect(point::Tuple{OInt,OInt}, c1::Tuple, c2::Tuple) = all(c1 .<= point .<= c2)

function draw_object!(grid::Array{OInt,2}, object)
    for i = 1:size(object.shape)[1], j = 1:size(object.shape)[2]
        p = (i, j) .+ object.position .- (1, 1)
        if point_in_rect(p, (1, 1), size(grid)) && object.shape[i, j] != OInt(-1)
            grid[p...] = object.shape[i, j]
        end
    end
    grid
end

end
