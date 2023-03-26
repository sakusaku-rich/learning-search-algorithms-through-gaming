include("./03_AlphaBeta.jl")

module ExecutionSpeedCalculator
using ..AlternateMazeStateGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions
using ..RandomAction: random_action
using Random: seed!
using Dates: now, Millisecond, DateTime

function get_sample_states(game_number::Int, h::Int, w::Int, end_turn::Int)::Vector{AlternateMazeState}
    states = []
    for seed in 1:game_number
        seed!(seed)
        state = AlternateMazeState(seed, h, w, end_turn)
        turn = rand(1:end_turn)
        for t in 1:turn
            advance!(state, random_action(state))
        end
        push!(states, state)
    end
    states
end

function calculate_execution_speed(ai::Pair, states::Vector{AlternateMazeState})
    start_time = now()
    for state in states
        ai.second(state)
    end
    diff = now() - start_time
    println("$(ai.first) take $(diff) ms to process $(length(states)) nodes")
end

end

# end_turn = 10
# states = ExecutionSpeedCalculator.get_sample_states(100, 3, 3, end_turn)
# ExecutionSpeedCalculator.calculate_execution_speed(
#     "alpha_beta_action" => state -> AlphaBetaAction.alpha_beta_action(state, end_turn),
#     states
# )
# ExecutionSpeedCalculator.calculate_execution_speed(
#     "mini_max_action" => state -> MiniMaxAction.mini_max_action(state, end_turn),
#     states
# )