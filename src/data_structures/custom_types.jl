
null_value(::Type) = missing
is_null_value(val, null_val) = ismissing(null_val) ? ismissing(val) : val == null_val

struct Color end
null_value(::Type{Color}) = -1
