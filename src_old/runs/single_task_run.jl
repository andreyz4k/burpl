using burpl: solve_and_check
# fname = "data/training/39a8645d.json"
fname = "data/training/0b148d64.json"
# fname = "data/training/22eb0ac0.json"
# fname = "data/training/0a938d79.json"
# fname = "data/training/5521c0d9.json"

TASKS = [
    "data/training/0a938d79.json",
    "data/training/0b148d64.json",
    "data/training/1cf80156.json",
    "data/training/25ff71a9.json",
    "data/training/39a8645d.json",
    "data/training/496994bd.json",
    "data/training/4c4377d9.json",
    "data/training/5582e5ca.json",
    "data/training/62c24649.json",
    "data/training/6d0aefbc.json",
    "data/training/6fa7a44f.json",
    "data/training/74dd1130.json",
    "data/training/8be77c9e.json",
    "data/training/9dfd6313.json",
    "data/training/b1948b0a.json",
    "data/training/c9e6f938.json",
    "data/training/d0f5fe59.json",
    "data/training/d13f3404.json",
    "data/training/ea786f4a.json",
    "data/training/eb281b96.json",
    "data/training/f25ffba3.json",
    "data/training/ff28f65a.json",
    "data/training/22eb0ac0.json",
    "data/training/d631b094.json",
    "data/training/68b16354.json",
    "data/training/5ad4f10b.json",
    "data/training/9172f3a0.json",
    "data/training/23b5c85d.json",
    "data/training/ea32f347.json",
]

@time begin
    print(solve_and_check(TASKS[end], debug=false))
end
