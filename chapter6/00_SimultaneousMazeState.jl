module SimultaneousMazeGame

using Random: seed!, rand

const DX = [-1, 1, 0, 0]
const DY = [0, 0, 1, -1]

@enum Action LEFT=1 RIGHT=2 DOWN=3 UP=4
@enum WinningStatus FIRST=1 SECOND=2 DRAW=3 NONE=4

mutable struct Character
    y::Int
    x::Int
    game_score::Int

    function Character(y::Int, x::Int, game_score::Int=0)
        new(y, x, game_score)
    end
end

mutable struct SimultaneousMazeState
    h::Int
    w::Int
    points::Matrix{Int}
    turn::Int
    characters::Vector{Character}
    end_turn::Int

    function SimultaneousMazeState(seed::Int, h::Int, w::Int, end_turn::Int)
        seed!(seed)
        characters = Character[
            Character(h ÷ 2 + 1, w ÷ 2, 0),
            Character(h ÷ 2 + 1, w ÷ 2 + 2, 0),
        ]
        points = zeros(Int, h, w)
        for y in 1:h
            for x in 1:w÷2+1
                point = rand(0:9)
                if characters[1].x == x && characters[1].y == y
                    continue
                end
                if characters[2].x == x && characters[2].y == y
                    continue
                end
                points[y, x] = point
                points[y, w - x + 1] = point
            end
        end
        new(h, w, points, 0, characters, end_turn)
    end
end

function is_done(state::SimultaneousMazeState)::Bool
    state.turn == state.end_turn
end

function to_string(state::SimultaneousMazeState)::String
    s = ""
    s *= "Player 1: $(state.characters[1].game_score) ($(state.characters[1].x), $(state.characters[1].y))\n"
    s *= "Player 2: $(state.characters[2].game_score) ($(state.characters[2].x), $(state.characters[2].y))\n"
    for h in 1:state.h
        for w in 1:state.w
            is_writeen = false
            for player_id in eachindex(state.characters)
                if state.turn % 2 == 1
                    player_id = (player_id % 2) + 1
                end
                character = state.characters[player_id]
                if character.x == w && character.y == h
                    if player_id == 1
                        s *= "A "
                    else
                        s *= "B "
                    end
                    is_writeen = true
                end
            end
            if !is_writeen
                if state.points[h, w] == 0
                    s *= ". "
                else
                    s *= string(state.points[h, w]) * " "
                end
            end
        end
        s *= "\n\n"
    end
    s
end

function advance!(state::SimultaneousMazeState, action1::Int, action2::Int)
    character = state.characters[1]
    character.x += DX[action1]
    character.y += DY[action1]
    point = state.points[character.y, character.x]
    if point > 0
        character.game_score += point
    end
    character = state.characters[2]
    character.x += DX[action2]
    character.y += DY[action2]
    point = state.points[character.y, character.x]
    if point > 0
        character.game_score += point
    end
    for character in state.characters
        state.points[character.y, character.x] = 0
    end
    state.turn += 1
end

function legal_actions(state::SimultaneousMazeState, player_id::Int)::Vector{Int}
    actions = Int[]
    character = state.characters[player_id]
    for action in 1:4
        y = character.y + DY[action]
        x = character.x + DX[action]
        if 1 <= y <= state.h && 1 <= x <= state.w
            push!(actions, action)
        end
    end
    actions
end

function get_winning_status(state::SimultaneousMazeState)::WinningStatus
    if is_done(state) 
        if state.characters[1].game_score > state.characters[2].game_score
            return FIRST
        end
        if state.characters[1].game_score < state.characters[2].game_score
            return SECOND
        end
        return DRAW
    end
    NONE
end

function play_game(ais::Vector{Pair{String, Function}}, seed::Int, h::Int, w::Int, end_turn::Int)
    state = SimultaneousMazeState(seed, h, w, end_turn)
    println(to_string(state))
    while !is_done(state)
        actions = Int[
            ais[1].second(state, 1),
            ais[2].second(state, 2),
        ]
        println("actions $(Action(actions[1])) $(Action(actions[2]))")
        advance!(state, actions[1], actions[2])
        println(to_string(state))
    end
end

end

module RandomAgent

using ..SimultaneousMazeGame: SimultaneousMazeState, legal_actions

function random_action(state::SimultaneousMazeState, player_id::Int)::Int
    actions = legal_actions(state, player_id)
    rand(actions)
end

end

# ais = Pair{String, Function}[
#     "random_action" => (state, player_id) -> RandomAgent.random_action(state, player_id),
#     "random_action" => (state, player_id) -> RandomAgent.random_action(state, player_id)
# ]
# SimultaneousMazeGame.play_game(ais, 0, 3, 3, 4)