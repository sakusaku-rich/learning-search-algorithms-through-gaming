include("./00_AlternateMazeState.jl")

module MiniMaxAgent

using ..AlternateMazeGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions
using ..RandomAgent: random_action

function get_score(state::AlternateMazeState)::Int
    state.characters[1].game_score - state.characters[2].game_score
end

function mini_max_score(state::AlternateMazeState, depth::Int)::Int
    if is_done(state) || depth == 0
        return get_score(state)
    end
    actions = legal_actions(state)
    if isempty(actions)
        return get_score(state)
    end
    best_score = -typemax(Int)
    for action in actions
        next_state = copy(state)
        advance!(next_state, action)
        score = -mini_max_score(next_state, depth - 1)
        if score > best_score
            best_score = score
        end
    end
    best_score
end

function mini_max_action(state::AlternateMazeState, depth::Int)::Int
    best_action = -1
    best_score = -typemax(Int)
    for action in legal_actions(state)
        next_state = copy(state)
        advance!(next_state, action)
        score = -mini_max_score(next_state, depth - 1)
        if score > best_score
            best_score = score
            best_action = action
        end
    end
    best_action
end

end

# end_turn = 4
# ais::Vector{Pair{String, Function}} = [
#     "mini_max_agent" => state -> MiniMaxAgent.mini_max_action(state, end_turn),
#     "random_agent" => state -> RandomAgent.random_action(state)
# ]
# AlternateMazeGame.play_game(0, ais, 3, 3, end_turn)