module MazeGame

using Random: seed!, rand

const DX = [1, -1, 0, 0]
const DY = [0, 0, 1, -1]

mutable struct Coord
    x::Int
    y::Int
end

mutable struct MazeState
    points::Matrix{Int}
    character::Coord
    h::Int
    w::Int
    end_turn::Int
    turn::Int
    game_score::Int
    evaluated_score::Int
    first_action::Int

    function MazeState(seed::Int, h::Int, w::Int, end_turn::Int)
        seed!(seed)
        character = Coord(
            mod(rand(Int, 1)[1], h) + 1,
            mod(rand(Int, 1)[1], w) + 1
        )
        points = zeros(Int, h, w)
        for i in 1:h
            for j in 1:w
                if i != character.x || j != character.y
                    points[i, j] = mod(rand(Int, 1)[1], 10)
                end
            end
        end
        new(points, character, h, w, end_turn, 0,  0, 0, -1)
    end
end

function evaluate_score!(state::MazeState)
    state.evaluated_score = state.game_score
end

function is_done(state::MazeState)::Bool
    state.turn == state.end_turn
end

function advance!(state::MazeState, action::Int)
    state.character.x += DX[action]
    state.character.y += DY[action]
    p = state.points[state.character.x, state.character.y]
    state.game_score += p
    state.points[state.character.x, state.character.y] = 0
    state.turn += 1
end

function legal_actions(state::MazeState)::Vector{Int}
    actions = []
    for i in 1:4
        tx = state.character.x + DX[i]
        ty = state.character.y + DY[i]
        if tx >= 1 && tx <= state.h && ty >= 1 && ty <= state.w
            push!(actions, i)
        end
    end
    actions
end

function to_string(state::MazeState)::String
    ss = ""
    ss *= "turn:\t$(state.turn)\n"
    ss *= "score:\t$(state.game_score)\n\n"
    for h in 1:state.h
        for w in 1:state.w
            if state.character.x == h && state.character.y == w
                ss *= "@"
            elseif state.points[h, w] > 0
                ss *= string(state.points[h, w])
            else
                ss *= "."
            end
        end
        ss *= "\n"
    end
    ss *= "\n\n"
    ss
end

end


module RandomAgent

using ..MazeGame: MazeState, legal_actions, advance!, to_string, is_done

function random_action(state::MazeState)::Int
    rand(legal_actions(state))
end

function play_game(seed::Int, h::Int, w::Int, end_turn::Int)
    state = MazeState(seed, h, w, end_turn)
    print(to_string(state))
    while !is_done(state)
        action = random_action(state)
        advance!(state, action)
        print(to_string(state))
    end
end
    
end

# RandomAgent.play_game(0, 10, 10, 10)