include("./02_TestWinrate.jl")

module AlphaBetaAction
using ..AlternateMazeGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions

function get_score(state::AlternateMazeState)::Int
    state.characters[1].game_score - state.characters[2].game_score
end

function alpha_beta_score(state::AlternateMazeState, alpha::Int, beta::Int, depth::Int)::Int
    if is_done(state) || depth == 0
        return get_score(state)
    end
    actions = legal_actions(state)
    if isempty(actions)
        return get_score(state)
    end
    for action in actions
        next_state = deepcopy(state)
        advance!(next_state, action)
        score = -alpha_beta_score(next_state, -beta, -alpha, depth - 1)
        if score > alpha
            alpha = score
        end
        if alpha >= beta
            return alpha
        end
    end
    alpha
end

function alpha_beta_action(state::AlternateMazeState, depth::Int)::Int
    best_action = -1
    alpha = -typemax(Int)
    beta = typemax(Int)
    for action in legal_actions(state)
        next_state = deepcopy(state)
        advance!(next_state, action)
        score = -alpha_beta_score(next_state, -beta, -alpha, depth)
        if score > alpha
            best_action = action
            alpha = score
        end
    end
    best_action
end

end

# end_turn = 4
# ais = [
#     "mini_max_action" => state -> MiniMaxAction.mini_max_action(state, end_turn),
#     "alpha_beta_action" => state -> AlphaBetaAction.alpha_beta_action(state, end_turn),
# ]
# TestFirstPlayerWinRate.test_first_player_win_rate(3, 3, end_turn, ais, 100)