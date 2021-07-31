
using ..DataStructures: Operation, Entry

function (op::Operation)(task_data)
    source_values = [task_data[k] for k in op.input_keys]
    results = op.method(source_values...)
    return Dict(k => v for (k, v) in zip(op.output_keys, results))
end
