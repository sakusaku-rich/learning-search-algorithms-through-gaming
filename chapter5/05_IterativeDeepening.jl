include("./04_TestSpeed.jl")

module Util

using Dates: now, Millisecond, DateTime

struct TimeKeeper
    start_time::DateTime
    time_threshold::Int
    function TimeKeeper(time_threshold::Int)
        new(now(), time_threshold)
    end
end

function is_time_over(time_keeper::TimeKeeper)::Bool
    now() - time_keeper.start_time > Millisecond(time_keeper.time_threshold)
end

end


module IterativeDeepeningAgent
using ..AlternateMazeGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions, Character
using ..Util: TimeKeeper, is_time_over
using Dates: now, Millisecond, DateTime

function get_score(state::AlternateMazeState)::Int
    state.characters[1].game_score - state.characters[2].game_score
end



function alpha_beta_score(state::AlternateMazeState, alpha::Int, beta::Int, depth::Int, time_keeper::TimeKeeper)::Int
    if is_time_over(time_keeper)
        return 0
    end
    if is_done(state) || depth == 0
        return get_score(state)
    end
    actions = legal_actions(state)
    if isempty(actions)
        return get_score(state)
    end
    for action in actions  
        next_state = copy(state)
        advance!(next_state, action)
        score = -alpha_beta_score(next_state, -beta, -alpha, depth - 1, time_keeper)
        if is_time_over(time_keeper)
            return 0
        end
        if score > alpha
            alpha = score
        end
        if alpha >= beta
            return alpha
        end
    end
    alpha
end

function iterative_deepening_action(state::AlternateMazeState, time_threshold::Int)::Int
    time_keeper = TimeKeeper(time_threshold)
    best_action = -1
    for depth in Iterators.countfrom()
        action = alpha_beta_action_with_time_threshold(state, depth, time_keeper)
        if is_time_over(time_keeper)
            break
        else
            best_action = action
        end
    end
    best_action
end

function alpha_beta_action_with_time_threshold(state::AlternateMazeState, depth::Int, time_keeper::TimeKeeper)::Int
    best_action = -1
    alpha = -typemax(Int)
    actions = legal_actions(state)
    for action in actions
        next_state = copy(state)
        advance!(next_state, action)
        score = -alpha_beta_score(next_state, -typemax(Int), -alpha, depth, time_keeper)
        if score > alpha
            best_action = action
            alpha = score
        end
        if is_time_over(time_keeper)
            return 1
        end
    end
    best_action
end

end

# w = 5
# h = 5
# end_turn = 10
# ais = [
#     "iterative_deepening_agent 100" => state -> IterativeDeepeningAgent.iterative_deepening_action(state, 100),
#     "iterative_deepening_agent 1" => state -> IterativeDeepeningAgent.iterative_deepening_action(state, 1),
# ]
# TestFirstPlayerWinRate.test_first_player_win_rate(w, h, end_turn, ais, 100)