# burpl

[![CI](https://github.com/andreyz4k/burpl/actions/workflows/main.yml/badge.svg)](https://github.com/andreyz4k/burpl/actions/workflows/main.yml)

An attempt to create a system that can solve problems from the [ARC](https://github.com/fchollet/ARC) benchmark.

The chosen approach is to mimic the thinking process that is performing by humans when solving these tasks.

When humans are looking at the problem they are not trying to apply some transformations to the input until it matches the output
but rather perform some abstract operations on both input and output creating a simpler internal representation
(I see two objects here, this object is repeated three times, etc) and
then try to explain all the data in the output either from constants or from the data derived from the input
(why the size of the output grid is 3x3? it's always this in this task. why there are three objects here? because there are three objects in the input).

So the process of searching for a solution goes as follows:

1. Start from an initial partial solution. Input is known, the output is unexplained. This solution goes to a priority queue.
2. On every iteration one partial solution is fetched from the priority queue.
3. For every unexplained field and for every known field we try to apply a list of abstract operations.
4. If this operation is applicable (they might need some specific type of input) we add it to the solution,
marking the new fields as unexplained/unused and the old ones as transformed.
5. Unexplained fields are checked if they can be explained by a constant value or some known value in other fields.
6. For each new intermediate solution we calculate a priority based on the complexity of the yet-unexplained data,
amount of cells that are already predicted correctly, and several heuristics approximating the likelihood that the last applied abstractor will lead to a final solution.
7. If there is a new solution that explains all the output with 0 errors, return.
8. All new solutions are pushed to the queue, go to step 2.

This is the problem of program synthesis, which means that we have a limited number of operations that can be combined,
making the space of possible solutions discreet and preventing us from using any sort of gradient descent.
On the other hand, the number of all the possible solutions grows exponentially, making it impossible to check all of them for any but the simplest tasks.

Fortunately, we don't need to check all the options all the time. As observed in humans, we penalize heavily too complex intermediate representations
and that can be used to prune huge parts of the search tree.

The important part is the choice of allowed abstract operations. One option would be to use the simplest predicates possible.
But that would mean that we won't use any prior knowledge about the underlying problem domain (Core Knowledge) and
the system will have to didact all of them from scratch all the time (like how we group same-colored cells into an object).
It's computationally unfeasible, so the chosen solution is to implement operations that are complex enough to catch most of the Core Knowledge
but simple and atomic enough so they will be able to be reused in many different tasks and combined in a different order.
The list of these abstract operations is definitely incomplete at the moment and will expand in the future to allow solving more tasks.

The system is written in Julia because of its speed, clean syntax (including multiple dispatch), and rich type system.
In the future, we may also try to make use of its differentiability feature to determine the values of some magical constants.

### How to start

1. Install julia
2. Clone the code
3. Start `julia --project=.` from the project root folder
4. Type `]` enable package manager mode
5. Run `instantiate` to download all the dependencies
6. Exit julia process
7. Go to the `test` folder
8. Run `julia --project=.. runtests.jl` to run all the tests
