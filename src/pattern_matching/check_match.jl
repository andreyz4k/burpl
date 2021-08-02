
using ..DataStructures: Entry

check_match(v1::Entry, v2::Entry) = v1.type == v2.type && check_match(v1.values, v2.values)

check_match(v1, v2) = v1 == v2

check_match(v1, v2::Either) = any(check_match(v1, option.value) for option in v2.options)
