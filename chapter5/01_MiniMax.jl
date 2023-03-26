include("./00_AlternateMazeState.jl")

module MiniMaxAction

using ..AlternateMazeGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions
using ..RandomAction: random_action

function get_score(state::AlternateMazeState)::Int
    state.characters[1].game_score - state.characters[2].game_score
end

function mini_max_score(state::AlternateMazeState, depth::Int)::Int
    if is_done(state) || depth == 0
        return get_score(state)
    end
    actions = legal_actions(state)
    if length(actions) == 0
        return get_score(state)
    end
    best_score = -typemax(Int)
    for action in actions
        next_state = deepcopy(state)
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
        next_state = deepcopy(state)
        advance!(next_state, action)
        score = -mini_max_score(next_state, depth - 1)
        if score > best_score
            best_score = score
            best_action = action
        end
    end
    best_action
end

function play_game(seed::Int, h::Int, w::Int, end_turn::Int)
    state = AlternateMazeState(seed, h, w, end_turn)
    while !is_done(state)
        println("1p ----")
        action = mini_max_action(state, end_turn)
        println("action: $(action)")
        advance!(state, action)
        println(to_string(state))
        if is_done(state)
            if get_winning_status(state) == 1
                println("winner: 1p")
                break
            elseif get_winning_status(state) == 2
                println("winner: 2p")
                break
            else
                println("DRAW")
                break
            end
        end
        println("2p ----")
        action = random_action(state)
        println("action: $(action)")
        advance!(state, action)
        println(to_string(state))
        if is_done(state)
            if get_winning_status(state) == 1
                println("winner: 1p")
                break
            elseif get_winning_status(state) == 2
                println("winner: 2p")
                break
            else
                println("DRAW")
                break
            end
        end
    end
end

end

# MiniMaxAction.play_game(0, 3, 3, 4)