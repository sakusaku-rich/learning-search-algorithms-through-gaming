include("00_SimultaneousMazeState.jl")

module PrimitiveMontecarloAgent

using ..SimultaneousMazeGame: SimultaneousMazeState, Action, get_winning_status, WinningStatus, advance!, legal_actions, FIRST, SECOND, DRAW, NONE
using ..RandomAgent: random_action


function playout(state::SimultaneousMazeState)::Float64
    if get_winning_status(state) == FIRST
        return 1.0
    elseif get_winning_status(state) == SECOND
        return 0.0
    elseif get_winning_status(state) == DRAW
        return 0.5
    end
    advance!(state, random_action(state, 1), random_action(state, 2))
    playout(state)
end

function primitive_montecarlo_action(state::SimultaneousMazeState, player_id::Int, playout_number::Int)::Int
    my_legal_actions = legal_actions(state, player_id)
    opp_legal_actions = legal_actions(state, mod(player_id, 2) + 1)
    best_value = -Inf
    best_action_index = -1
    for i in eachindex(my_legal_actions)
        value = 0.0
        for j in 1:playout_number
            next_state = deepcopy(state)
            if player_id == 1
                advance!(next_state, my_legal_actions[i], rand(opp_legal_actions))
            else
                advance!(next_state, rand(opp_legal_actions), my_legal_actions[i])
            end
            player1_win_rate = playout(next_state)
            win_rate = player_id == 1 ? player1_win_rate : 1.0 - player1_win_rate
            value += win_rate
        end
        if value > best_value
            best_value = value
            best_action_index = i
        end
    end
    my_legal_actions[best_action_index]
end

end


module FirstPlayerWinRateTester
using ..SimultaneousMazeGame: SimultaneousMazeState, Action, get_winning_status, advance!, legal_actions, is_done, FIRST, SECOND, DRAW, NONE, to_string

function get_first_player_score_for_win_rate(state::SimultaneousMazeState)::Float64
    winnnig_status = get_winning_status(state)
    if winnnig_status == FIRST
        return 1.0
    elseif winnnig_status == SECOND
        return 0.0
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
        state = SimultaneousMazeState(seed, h, w, end_turn)
        while true
            advance!(
                state, 
                ais[1].second(state, 1),
                ais[2].second(state, 2)
            )
            if is_done(state)
                    break
            end
        end
        win_rate_point = get_first_player_score_for_win_rate(state)
        first_player_win_rate += win_rate_point
        println("seed: $(seed) win_rate: $(first_player_win_rate / seed)")
    end
    first_player_win_rate /= game_number
    println("Winnig rate of $(ais[1].first) to $(ais[2].first):\t$(first_player_win_rate)")
end

end

# ais = Pair{String, Function}[
#     "primitive_montecarlo_action" => (state::SimultaneousMazeGame.SimultaneousMazeState, player_id::Int) -> PrimitiveMontecarloAgent.primitive_montecarlo_action(state, player_id, 1000),
#     "random_action" => (state::SimultaneousMazeGame.SimultaneousMazeState, player_id::Int) -> RandomAgent.random_action(state, player_id),
# ]
# FirstPlayerWinRateTester.test_first_player_win_rate(5, 5, 20, ais, 500)