using Random: seed!, rand
using Dates: now, Millisecond, DateTime
using Distributed

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
        new(points, character, h, w, end_turn, 0, 0, 0, -1)
    end
end

function operator(state1::MazeState, state2::MazeState)::Bool
    state1.evaluated_score < state2.evaluated_score
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

function evaluate_score!(state::MazeState)
    state.evaluated_score = state.game_score
end

function chokudai_search_action_with_time_threshold(state::MazeState, beam_width::Int, beam_depth::Int, time_threshold::Int)::Int

    time_keeper = TimeKeeper(time_threshold)

    beam = Vector{MazeState}[]
    @sync @distributed for _ in 1:beam_depth+1
        push!(beam, MazeState[])
    end
    push!(beam[1], state)

    for bn in Iterators.countfrom()
        if bn > beam_depth
            break
        end
        for t in 1:beam_depth
            now_beam = beam[t]
            next_beam = beam[t + 1]
            for i in 1:beam_width
                if length(now_beam) == 0
                    break
                end
                now_state = now_beam[1]
                if is_done(now_state)
                    break
                end
                popfirst!(now_beam)

                la = legal_actions(now_state)
                @sync @distributed for action in la
                    next_state = deepcopy(now_state)
                    advance!(next_state, action)
                    if t == 1
                        next_state.first_action = action
                    end
                    evaluate_score!(next_state)
                    push!(next_beam, next_state)
                end
            end
            beam[t + 1] = sort(next_beam, by=state->state.evaluated_score, rev=true)
        end
        if is_time_over(time_keeper)
            break
        end
    end

    for t in Iterators.countfrom(beam_depth + 1, -1)
        if length(beam[t]) > 0
            return beam[t][1].first_action
        end
    end

    return -1
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

function test_ai_score(game_number::Int, end_turn::Int, time_threshold::Int)
    score_mean = 0.0
    @sync @distributed for seed in 1:game_number
        state = MazeState(seed, 30, 30, end_turn)
        while !is_done(state)
            action = chokudai_search_action_with_time_threshold(state, 1, end_turn, time_threshold)
            advance!(state, action)
        end
        score_mean += state.game_score
    end
    score_mean /= game_number
    println("score mean: $(score_mean)")
end

println("dummy: ")
test_ai_score(1, 100, 1)
println("1ms: ")
test_ai_score(100, 100, 1)
println("10ms: ")
test_ai_score(100, 100, 10)