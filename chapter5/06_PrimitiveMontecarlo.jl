include("./05_IterativeDeepening.jl")

module PrimitiveMontecarloAction
using ..AlternateMazeGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions
using ..RandomAction: random_action

function playout(state::AlternateMazeState)::Float64
    winning_status = get_winning_status(state)
    if winning_status == 1
        return 1.0
    elseif winning_status == 2
        return 0.0
    elseif winning_status == 0
        return 0.5
    else
        advance!(state, random_action(state))
        return 1.0 - playout(state)
    end
end

function primitive_montecarlo_action(state::AlternateMazeState, playout_number::Int)::Int
    actions = legal_actions(state)
    values = repeat([0.0], length(actions))
    cnts = repeat([0], length(actions))
    for cnt in 1:playout_number
        index = mod(cnt, length(actions)) + 1
        next_state = deepcopy(state)
        advance!(next_state, actions[index])
        values[index] += 1.0 - playout(next_state)
        cnts[index] += 1
    end
    best_action_index = -1
    best_score = -floatmax(Float64)
    for index in 1:length(actions)
        value_mean = values[index] / cnts[index]
        if value_mean > best_score
            best_score = value_mean
            best_action_index = index
        end
    end
    actions[best_action_index]
end

end

# w = 5
# h = 5
# end_turn = 10
# ais = [
#     "primitive_montecarlo_action 3000" => state -> PrimitiveMontecarloAction.primitive_montecarlo_action(state, 3000),
#     "random_action" => state -> RandomAction.random_action(state),
# ]
# TestFirstPlayerWinRate.test_first_player_win_rate(w, h, end_turn, ais, 100)