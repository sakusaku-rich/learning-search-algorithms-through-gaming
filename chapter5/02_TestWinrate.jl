
include("./01_MiniMax.jl")

module TestFirstPlayerWinRate
using ..AlternateMazeGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions
using ..MiniMaxAgent: mini_max_action

function is_first_player(state::AlternateMazeState)::Bool
    state.turn % 2 == 0
end

function get_first_player_score_for_win_rate(state::AlternateMazeState)::Float64
    winnnig_status = get_winning_status(state)
    if winnnig_status == 1
        if is_first_player(state)
            return 1.0
        else
            return 0.0
        end
    elseif winnnig_status == 2
        if is_first_player(state)
            return 0.0
        else
            return 1.0
        end
    else
        return 0.5
    end
end

function test_first_player_win_rate(
    h::Int, 
    w::Int, 
    end_turn::Int,
    ais::Vector{Pair{String, Function}}, 
    game_number::Int
)
    first_player_win_rate = 0.0
    for seed in 1:game_number
        base_state = AlternateMazeState(seed, h, w, end_turn)
        for j in [1,2]
            state = copy(base_state)
            first_ai = ais[j]
            second_ai = ais[j % 2 + 1]
            while true
                advance!(state, first_ai.second(state))
                if is_done(state)
                    break
                end
                advance!(state, second_ai.second(state))
                if is_done(state)
                    break
                end
            end
            win_rate_point = get_first_player_score_for_win_rate(state)
            if j == 2
                win_rate_point = 1.0 - win_rate_point
            end
            first_player_win_rate += win_rate_point
        end
        println("seed: $(seed) win_rate: $(first_player_win_rate / (2 * seed))")
    end
    first_player_win_rate /= 2 * game_number
    println("Winnig rate of $(ais[1].first) to $(ais[2].first):\t$(first_player_win_rate)")
end

end

# end_turn = 4
# ais = [
#     "mini_max_agent" => state -> MiniMaxAgent.mini_max_action(state, end_turn),
#     "random_agent" => state -> RandomAgent.random_action(state)
# ]
# TestFirstPlayerWinRate.test_first_player_win_rate(3, 3, end_turn, ais, 100)