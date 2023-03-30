module WallMazeGame

using Random: seed!, rand

const DX = [-1, 1, 0, 0]
const DY = [0, 0, 1, -1]

mutable struct Coord
    x::Int
    y::Int
end

mutable struct WallMazeState
    h::Int
    w::Int
    end_turn::Int
    points::Matrix{Int}
    walls::Matrix{Int}
    character::Coord
    turn::Int
    evaluated_score::Int
    game_score::Int
    first_action::Int

    function WallMazeState(seed::Int, h::Int, w::Int, end_turn::Int)
        seed!(seed)
        character = Coord(rand(1:w), rand(1:h))
        points = zeros(Int, h, w)
        walls = zeros(Int, h, w)
        for y in Iterators.countfrom(2, 2)
            if y > h
                break
            end
            for x in Iterators.countfrom(2, 2)
                if x > w
                    break
                end
                ty = y
                tx = x
                if ty == character.y && tx == character.x
                    continue
                end
                walls[y, x] = 1
                direction_size = 3
                if y == 1
                    direction_size = 4
                end
                direction = rand(1:direction_size)
                ty += DY[direction]
                tx += DX[direction]
                
                if ty == character.y && tx == character.x
                    continue
                end
                walls[ty, tx] = 1
            end
        end
    
        for y in 1:h
            for x in 1:w
                if y == character.y && x == character.x
                    continue
                end
                points[y, x] = rand(0:9)
            end
        end
        new(h, w, end_turn, points, walls, character, 0, 0, 0, 0)
    end

end


function legal_actions(state::WallMazeState)::Vector{Int}
    actions = Int[]
    for action in 1:4
        ty = state.character.y + DY[action]
        tx = state.character.x + DX[action]
        if 1 <= ty <= state.h && 1 <= tx <= state.w && state.walls[ty, tx] == 0
            push!(actions, action)
        end
    end
    actions
end


function to_string(state::WallMazeState)::String
    s = ""
    s *= "turn: $(state.turn)\n"
    s *= "game_score: $(state.game_score)\n"
    for y in 1:state.h
        for x in 1:state.w
            if state.walls[y, x] == 1
                s *= "# "
            elseif state.character.y == y && state.character.x == x
                s *= "@ "
            else
                if state.points[y, x] == 0
                    s *= ". "
                else
                    s *= string(state.points[y, x]) * " "
                end
            end
        end
        s *= "\n"
    end
    s
end

function advance!(state, action::Int)
    if state.turn == 0
        state.first_action = action
    end
    ty = state.character.y + DY[action]
    tx = state.character.x + DX[action]
    state.character.y = ty
    state.character.x = tx
    if state.points[ty, tx] > 0
        state.game_score += state.points[ty, tx]
        state.points[ty, tx] = 0
    end
    state.turn += 1
end

function is_done(state::WallMazeState)::Bool
    state.turn == state.end_turn
end

function play_game(seed::Int, h::Int, w::Int, end_turn::Int, ai::Pair)::Int
    state = WallMazeState(seed, h, w, end_turn)
    println(to_string(state))
    while !is_done(state)
        advance!(state, ai.second(state))
        println(to_string(state))
    end
    state.evaluated_score
end
    
end

module RandomAgent
using ..WallMazeGame: legal_actions, WallMazeState

function random_action(state::WallMazeState)::Int
    rand(legal_actions(state))
end

end

# ai = "random_agent" => state -> RandomAgent.random_action(state)
# WallMazeGame.play_game(0, 5, 5, 4, ai)