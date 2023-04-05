include("./00_MazeState.jl")


module GreedyAgent

using ..MazeGame: MazeState, legal_actions, advance!, to_string, is_done, evaluate_score!



function greedy_action(state::MazeState)::Int
    la = legal_actions(state)
    best_score = -typemax(Int)
    best_action = -1
    for action in la
        new_state = copy(state)
        advance!(new_state, action)
        evaluate_score!(new_state)
        if new_state.evaluated_score > best_score
            best_score = new_state.evaluated_score
            best_action = action
        end
    end
    @assert best_action != -1
    best_action
end

function play_game(seed::Int, h::Int, w::Int, end_turn::Int)
    state = MazeState(seed, h, w, end_turn)
    print(to_string(state))
    while !is_done(state)
        action = greedy_action(state)
        advance!(state, action)
        print(to_string(state))
    end
end

end

# GreedyAgent.play_game(0, 5, 5, 10)