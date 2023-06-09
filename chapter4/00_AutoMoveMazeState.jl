

module AutoMoveMazeGame

using Random: seed!, rand

const H = 5
const W = 5
const END_TURN = 5
const CHARACTER_N = 3
const DX = [-1, 1, 0, 0]
const DY = [0, 0, 1, -1]

mutable struct Coord
    x::Int
    y::Int
end

Base.copy(c::Coord) = Coord(c.x, c.y)

mutable struct AutoMoveMazeState
    points::Matrix{Int}
    turn::Int
    characters::Vector{Coord}
    game_score::Int
    evaluated_score::Int

    function AutoMoveMazeState(seed::Int)
        seed!(seed)
        characters = Coord[]
        for i in 1:CHARACTER_N
            push!(characters, Coord(-1, -1))
        end
        points = zeros(Int, H, W)
        for i in 1:H
            for j in 1:W
                points[i, j] = mod(rand(Int, 1)[1], 9) + 1
            end
        end
        new(points, 0, characters, 0, 0)
    end

    function AutoMoveMazeState(points::Matrix{Int}, turn::Int, characters::Vector{Coord}, game_score::Int, evaluated_score::Int)
        new(points, turn, characters, game_score, evaluated_score)
    end
end

Base.copy(state::AutoMoveMazeState) = AutoMoveMazeState(
    copy(state.points),
    state.turn,
    copy(state.characters),
    state.game_score,
    state.evaluated_score
)

function init!(state::AutoMoveMazeState)
    for character in state.characters
        character.x = rand(1:W)
        character.y = rand(1:H)
    end
end


function transition!(state::AutoMoveMazeState)
    character = state.characters[rand(1:CHARACTER_N)]
    character.x = rand(1:W)
    character.y = rand(1:H)
end

function set_character!(characters::Vector{Coord}, character_id::Int, x::Int, y::Int)
    characters[character_id].x = x
    characters[character_id].y = y
end

function get_score(state::AutoMoveMazeState, is_print::Bool)
    tmp_state = copy(state)

    for character in state.characters
        tmp_state.points[character.x, character.y] = 0
    end

    while !is_done(tmp_state)
        advance!(tmp_state)
        if is_print
            println(to_string(state))
        end
    end

    tmp_state.game_score
end

function move_player!(state::AutoMoveMazeState, character_id::Int)
    character = state.characters[character_id]
    best_point = -Inf
    best_action_index = 1
    for action in 1:4
        tx = character.x + DX[action]
        ty = character.y + DY[action]
        if ty >= 1 && ty <= H && tx >= 1 && tx <= W
            point = state.points[tx, ty]
            if point > best_point
                best_point = point
                best_action_index = action
            end
        end
    end

    character.x += DX[best_action_index]
    character.y += DY[best_action_index]
end

function advance!(state::AutoMoveMazeState)
    for character_id in 1:CHARACTER_N
        move_player!(state, character_id)
    end
    for character in state.characters
        point = state.points[character.x, character.y]       
        state.game_score += point
        state.points[character.x, character.y] = 0
    end
    state.turn += 1
end

function is_done(state::AutoMoveMazeState)
    state.turn == END_TURN
end

function to_string(state::AutoMoveMazeState)::String
    ss = "turn:\t$(state.turn)\n"
    ss *= "score:\t$(state.game_score)\n\n"
    for h in 1:H
        for w in 1:W
            exists_character = false
            for character in state.characters
                if character.x == h && character.y == w
                    exists_character = true
                end
            end
            if exists_character
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

function play_game(ai, seed::Int)
    state = AutoMoveMazeState(seed)
    state = ai.second(state)
    println(to_string(state))
    score = get_score(state, true)
    println("Score of $(ai.first): $(score)")
end

end

module RandomAgent

using ..AutoMoveMazeGame: AutoMoveMazeState, CHARACTER_N, H, W, set_character!
using Random

function random_action(state::AutoMoveMazeState)
    now_state = copy(state)
    for character_id in 1:CHARACTER_N
        x = rand(1:W)
        y = rand(1:H)
        set_character!(now_state.characters, character_id, x, y)
    end
    now_state
end

end


# ai = "random_action" => state -> RandomAgent.random_action(state)
# AutoMoveMazeGame.play_game(ai, 0)