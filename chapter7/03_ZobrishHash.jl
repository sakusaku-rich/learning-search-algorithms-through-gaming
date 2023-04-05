

module Zobrish

using Random: rand, seed!

struct Hash
    points::Array{Int64, 3}
    character::Matrix{Int64}

    function Hash(points::Array{Int64, 3}, character::Matrix{Int64})
        new(points, character)
    end

    function Hash(seed::Int, h::Int, w::Int)::Hash
        seed!(seed)
        points = zeros(Int, h, w, 9)
        character = zeros(Int, h, w)
        for y in 1:h
            for x in 1:w
                for p in 1:9
                    points[y, x, p] = rand(1:typemax(Int))
                end
                character[y, x] = rand(1:typemax(Int))
            end
        end
        new(points, character)
    end
end

Base.copy(hash::Hash) = Hash(copy(hash.points), copy(hash.character))

end


module WallMazeGame

using Random: seed!, rand
using ..Zobrish: Hash

const DX = [-1, 1, 0, 0]
const DY = [0, 0, 1, -1]

mutable struct Coord
    x::Int
    y::Int
end

Base.copy(coord::Coord) = Coord(coord.x, coord.y)

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
    base_hash::Hash
    hash::Int
    ref_count::Int64

    function WallMazeState(h::Int, w::Int, end_turn::Int, points::Matrix{Int}, walls::Matrix{Int}, character::Coord, turn::Int, evaluated_score::Int, game_score::Int, first_action::Int, base_hash::Hash, hash::Int, ref_count::Int64)
        new(h, w, end_turn, points, walls, copy(character), turn, evaluated_score, game_score, first_action, copy(base_hash), hash, ref_count)
    end

    function WallMazeState(seed::Int, h::Int, w::Int, end_turn::Int, base_hash::Hash)
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
        hash = init_hash(base_hash, character, points)
        new(h, w, end_turn, points, walls, character, 0, 0, 0, 0, base_hash, hash, 1)
    end
end
Base.copy(state::WallMazeState) = WallMazeState(state.h, state.w, state.end_turn, copy(state.points), copy(state.walls), copy(state.character), state.turn, state.evaluated_score, state.game_score, state.first_action, copy(state.base_hash), state.hash, state.ref_count)



function init_hash(base_hash::Hash, character::Coord, points::Matrix{Int})::Int
    hash = 0
    hash ⊻= base_hash.character[character.y, character.x]
    for y in 1:size(points, 1)
        for x in 1:size(points, 2)
            if points[y, x] > 0
                hash ⊻= base_hash.points[y, x, points[y, x]]
            end
        end
    end
    hash
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

function advance!(state::WallMazeState, action::Int)
    state.hash ⊻= state.base_hash.character[state.character.y, state.character.x]
    ty = state.character.y + DY[action]
    tx = state.character.x + DX[action]
    state.character.y = ty
    state.character.x = tx
    point = state.points[ty, tx]
    if point > 0
        state.hash ⊻= state.base_hash.points[ty, tx, point]
        state.game_score += point
        state.points[ty, tx] = 0
    end
    state.turn += 1
end

function is_done(state::WallMazeState)::Bool
    state.turn == state.end_turn
end

function evaluate!(state::WallMazeState)
    state.evaluated_score = state.game_score
end
    
end

module DistanceEvaluater

using ..WallMazeGame: WallMazeState, Coord, DX, DY, legal_actions, advance!, is_done

struct DistanceCoord
    y::Int
    x::Int
    distance::Int
end

function get_distance_to_nearest_point(state::WallMazeState)::Int
    que = DistanceCoord[
        DistanceCoord(state.character.y, state.character.x, 0)
    ]
    check = falses(state.h, state.w)
    while !isempty(que)
        tmp_coord = popfirst!(que)
        if state.points[tmp_coord.y, tmp_coord.x] > 0
            return tmp_coord.distance
        end
        check[tmp_coord.y, tmp_coord.x] = true
        for action in 1:4
            ty = tmp_coord.y + DY[action]
            tx = tmp_coord.x + DX[action]
            if 1 <= ty <= state.h && 1 <= tx <= state.w && state.walls[ty, tx] == 0 && !check[ty, tx]
                push!(que, DistanceCoord(ty, tx, tmp_coord.distance + 1))
            end
        end
    end
    state.h * state.w
end

function evaluate!(state::WallMazeState, h::Int, w::Int)
    state.evaluated_score = state.game_score * h * w - get_distance_to_nearest_point(state)
end

end


module BeamSearchWIthHashCheckAgent

using ..WallMazeGame: WallMazeState, advance!, to_string, is_done, legal_actions, copy, Coord
using ..DistanceEvaluater: evaluate!
using DataStructures: PriorityQueue, dequeue!

function beam_search_action(state::WallMazeState, beam_width::Int, beam_depth::Int)::Int64
    now_beam = PriorityQueue{WallMazeState, Int}(Base.Order.Reverse)
    push!(now_beam, state => state.evaluated_score)
    best_state = state
    hash_check = Set(Int[])
    for t in 1:beam_depth
        next_beam = PriorityQueue{WallMazeState, Int}(Base.Order.Reverse)
        for i in beam_width
            if isempty(now_beam)
                break
            end
            now_state = dequeue!(now_beam)
            actions = legal_actions(now_state)
            for action in actions
                next_state = copy(now_state)
                advance!(next_state, action)
                if t > 1 && next_state.hash in hash_check
                    continue
                end
                push!(hash_check, next_state.hash)
                if t == 1
                    next_state.first_action = action
                end
                evaluate!(next_state, state.h, state.w)
                push!(next_beam, next_state => next_state.evaluated_score)
            end
        end
        now_beam = next_beam
        if isempty(now_beam)
            break
        end
        best_state = first(now_beam)[1]
        if is_done(best_state)
            break
        end
    end
    best_state.first_action
end

end

module AITester

using ..WallMazeGame: WallMazeState, is_done, advance!
using ..Zobrish: Hash
using Distributed
using Dates: now, Millisecond

function test_ai_score(ai::Pair, game_number::Int, h::Int, w::Int, end_turn::Int, base_hash::Hash)
    score_mean = 0.0
    for seed in 1:game_number
    # @sync @distributed for seed in 1:game_number
        state = WallMazeState(seed, h, w, end_turn, base_hash)
        while !is_done(state)
            advance!(state, ai.second(state))
        end
        score_mean += state.game_score
    end
    score_mean /= game_number
    println("score mean: $(score_mean)")
end

function test_ai_speed(ai::Pair, game_number::Int, per_game_number::Int, h::Int, w::Int, end_turn::Int, base_hash::Hash)
    diff_sum = Millisecond(0)
    for i in 1:game_number
        state = WallMazeState(i, h, w, end_turn, base_hash)
        start_time = now()
        for j in 1:per_game_number
            ai.second(state)
        end
        diff = now() - start_time
        diff_sum += diff
    end
    time_mean = diff_sum.value / game_number
    println("Time of $(ai.first) $(time_mean)ms")
end

end



# h = 7
# w = 7
# end_turn = 49
# beam_width = 100
# beam_depth = end_turn
# base_hash = Zobrish.Hash(0, h, w)
# ai = "beam_search_agent" => state -> BeamSearchWIthHashCheckAgent.beam_search_action(state, beam_width, beam_depth)
# AITester.test_ai_score(ai, 100, h, w, end_turn, base_hash)