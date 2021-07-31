
using ..Operations: CopyField

function find_exact_match(branch, key)
    if haskey(branch.known_fields, key)
        return find_exact_match_for_known(branch, key)
    else
        return find_exact_match_for_unknown(branch, key)
    end
end

function find_exact_match_for_known(branch, input_key)
    input_entry = branch.known_fields[input_key]
    skipmissing(
        imap(branch.unknown_fields) do (output_key, output_entry)
            if check_match(input_entry, output_entry)
                return Operation(CopyField, [input_key], [output_key])
            end
            return missing
        end,
    )
end

function find_exact_match_for_unknown(branch, output_key)
    output_entry = branch.unknown_fields[output_key]
    skipmissing(
        imap(branch.known_fields) do (input_key, input_entry)
            if check_match(input_entry, output_entry)
                return Operation(CopyField(), [input_key], [output_key])
            end
            return missing
        end,
    )
end
