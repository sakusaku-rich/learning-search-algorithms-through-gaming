using Random: seed!, rand

const H = 3
const W = 3
const END_TURN = 4
const DX = [-1, 1, 0, 0]
const DY = [0, 0, 1, -1]


mutable struct Character
    x::Int
    y::Int
    game_score::Int

    function Character(x::Int, y::Int, game_score::Int=0)
        new(x, y, game_score)
    end
end


mutable struct AlternateMazeState
    points::Matrix{Int}
    turn::Int
    characters::Vector{Character}

    function AlternateMazeState(
        seed::Int, 
        characters::Vector{Character} = Character[
            Character(Int(floor(H / 2)), Int(floor(W / 2))-1, 0),
            Character(Int(ceil(H / 2)), Int(ceil(W / 2))+1, 0),
        ]
    )
        seed!(seed)
        points = zeros(Int, H, W)
        for y in 1:H
            for x in 1:W
                point = rand(0:9)
                if characters[1].x == x && characters[1].y == y
                    continue
                end
                if characters[2].x == x && characters[2].y == y
                    continue
                end
                points[y, x] = point
            end
        end
        new(points, 0, characters)
    end
end

function is_done(state::AlternateMazeState)::Bool
    state.turn == END_TURN
end

function advance!(state::AlternateMazeState, action::Int)
    character = state.characters[1]
    character.x += DX[action]
    character.y += DY[action]
    point = state.points[character.y, character.x]
    if point > 0
        character.game_score += point
        state.points[character.y, character.x] = 0
    end
    state.turn += 1
    swap_characters!(state.characters)
end

function swap_characters!(characters::Vector{Character})
    push!(characters, popfirst!(characters))
end

function legal_actions(state::AlternateMazeState)::Vector{Int}
    actions = Int[]
    character = state.characters[1]
    for action in 1:4
        tx = character.x + DX[action]
        ty = character.y + DY[action]
        if tx >= 1 && tx <= W && ty >= 1 && ty <= H
            push!(actions, action)
        end
    end
    actions
end

function get_winning_status(state::AlternateMazeState)::Int
    if is_done(state)
        if state.characters[1].game_score > state.characters[2].game_score
            return 1
        elseif state.characters[1].game_score < state.characters[2].game_score
            return 2
        else
            return 0
        end
    else
        return -1
    end
end

function to_string(state::AlternateMazeState)::String
    s = ""
    for player_id in 1:length(state.characters)
        if state.turn % 2 == 1
            player_id = (player_id % 2) + 1
        end
        character = state.characters[player_id]
        s *= "Player $(player_id): $(character.game_score) ($(character.x), $(character.y))\n"
    end
    for h in 1:H
        for w in 1:W
            is_writeen = false
            for player_id in 1:length(state.characters)
                if state.turn % 2 == 1
                    player_id = (player_id % 2) + 1
                end
                character = state.characters[player_id]
                if character.x == h && character.y == w
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

function random_action(state::AlternateMazeState)::Int
    rand(legal_actions(state))
end

function play_game(seed::Int)
    state = AlternateMazeState(seed)
    while !is_done(state)
        println("1p ----")
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

play_game(0)