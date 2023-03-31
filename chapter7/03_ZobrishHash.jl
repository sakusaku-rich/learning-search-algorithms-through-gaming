

module Zobrish

using Random: rand, seed!

struct Hash
    points::Array{Int64, 3}
    character::Matrix{Int64}

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
        new(h, w, end_turn, points, walls, character, 0, 0, 0, 0, base_hash, hash)
    end

end


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

using ..WallMazeGame: WallMazeState, advance!, to_string, is_done, legal_actions
using ..DistanceEvaluater: evaluate!

function beam_search_action(state::WallMazeState, beam_width::Int, beam_depth::Int)::Int64
    now_beam = WallMazeState[state]
    best_state = state
    hash_check = Set(Int[])
    for t in 1:beam_depth
        next_beam = WallMazeState[]
        for i in beam_width
            if isempty(now_beam)
                break
            end
            now_state = popfirst!(now_beam)
            actions = legal_actions(now_state)
            for action in actions
                next_state = deepcopy(now_state)
                advance!(next_state, action)
                # println("****")
                # println(t)
                # println(next_state.hash)
                # println(hash_check)
                if t > 1 && next_state.hash in hash_check
                    continue
                end
                push!(hash_check, next_state.hash)
                if t == 1
                    next_state.first_action = action
                end
                push!(next_beam, next_state)
            end
        end
        evaluate!.(next_beam, state.h, state.w)
        now_beam = sort(next_beam, by=state->state.evaluated_score, rev=true)
        if !isempty(now_beam)
            best_state = now_beam[begin]
        end
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


function test_ai_score(ai::Pair, game_number::Int, h::Int, w::Int, end_turn::Int, base_hash::Hash)
    score_mean = 0.0
    @sync @distributed for seed in 1:game_number
        state = WallMazeState(seed, h, w, end_turn, base_hash)
        while !is_done(state)
            advance!(state, ai.second(state))
        end
        score_mean += state.game_score
    end
    score_mean /= game_number
    println("score mean: $(score_mean)")
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