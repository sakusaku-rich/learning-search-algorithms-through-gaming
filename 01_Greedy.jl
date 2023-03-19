using Random: seed!, rand

const INF = 1e9


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
    dx::Vector{Int} 
    dy::Vector{Int}
    evaluated_score::Int

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
        new(points, character, h, w, end_turn, 0,  0, [1, -1, 0, 0], [0, 0, 1, -1], 0)
    end
end

function evaluate_score!(state::MazeState)
    state.evaluated_score = state.game_score
end

function is_done(state::MazeState, end_turn::Int)::Bool
    state.turn == end_turn
end

function advance!(state::MazeState, action::Int)
    state.character.x += state.dx[action]
    state.character.y += state.dy[action]
    p = state.points[state.character.x, state.character.y]
    state.game_score += p
    state.points[state.character.x, state.character.y] = 0
    state.turn += 1
end

function legal_actions(state::MazeState)::Vector{Int}
    actions = []
    for i in 1:4
        tx = state.character.x + state.dx[i]
        ty = state.character.y + state.dy[i]
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

function random_action(state::MazeState)::Int
    la = legal_actions(state)
    la[rand(1:length(la))]
end

function greedy_action(state::MazeState)::Int
    la = legal_actions(state)
    best_score = -INF
    best_action = -1
    for action in la
        new_state = deepcopy(state)
        advance!(new_state, action)
        evaluate_score!(new_state)
        if new_state.evaluated_score > best_score
            best_score = new_state.evaluated_score
            best_action = action
        end
    end
    @assert best_action != -1
    best_action
end

function play_game(seed::Int, h::Int, w::Int, end_turn::Int)
    state = MazeState(seed, h, w, end_turn)
    print(to_string(state))
    while !is_done(state, end_turn)
        # action = random_action(state)
        action = greedy_action(state)
        advance!(state, action)
        print(to_string(state))
    end
end

play_game(0, 3, 4, 10)