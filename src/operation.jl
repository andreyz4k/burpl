module Operations

struct Operation
    func
    input_keys
    output_keys
    description
end

(op::Operation)(input_grid, output_grid, observed_data) =
    op.func(input_grid, output_grid, observed_data)

Base.show(io::IO, op::Operation) = print(io, op.description)

end
