
export ObjectPrior
module ObjectPrior

struct Object
    shape::Array{Int,2}
    position::Tuple{Int,Int}
end

Base.:(==)(a::Object, b::Object) = a.shape == b.shape && a.position == b.position

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
    component = fill(-1, maxx - minx + 1, maxy - miny + 1)
    for p in points
        component[p[1] - minx + 1, p[2] - miny + 1] = grid[p...]
    end
    (minx, miny), component
end

function find_objects(grid::Array{Int,2})
    objects = []

    visited = Set()
    s = size(grid)

    for i in 1:s[1], j in 1:s[2]
        if !in((i, j), visited)
            points = find_component(grid, i, j, visited)
            position, component = normalize_component(points, grid)
            push!(objects, Object(component, position))
        end
    end

    return objects
end

function draw_object!(grid::Array{Int,2}, object)
    for i in 1:size(object.shape)[1], j in 1:size(object.shape)[2]
        p = (i, j) .+ object.position .- (1, 1)
        if (1, 1) <= p <= size(grid)
            grid[p...] = object.shape[i, j]
        end
    end
    grid
end

end
