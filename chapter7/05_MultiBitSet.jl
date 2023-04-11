include("03_ZobrishHash.jl")

module MultiBitSet

using ..Zobrish: Hash
using ..WallMazeGame: Coord, WallMazeState, DX, DY, init_hash, advance!, legal_actions, is_done, to_string
using Distributed
using Dates: now, Millisecond
using DataStructures: PriorityQueue, dequeue!, enqueue!, Deque

struct Mat
    bits::Vector{UInt64}
    function Mat(h::Int64)
        new([0 for _ in 1:h])
    end
    function Mat(bits::Vector{UInt64})
        new(copy(bits))
    end
end

Base.copy(mat::Mat) = Mat(mat.bits)

function get(mat::Mat, y::Int, x::Int)::Bool
    mat.bits[y] & (1 << (x-1)) != 0
end

function set!(mat::Mat, y::Int, x::Int)
    mat.bits[y] |= 2^(x-1)
end

function del!(mat::Mat, y::Int, x::Int)
    mat.bits[y] &= ~(1 << (x-1))
end

function up_mat(mat::Mat, h::Int)::Mat
    ret_mat = copy(mat)
    for y in 1:h-1
        ret_mat.bits[y] |= ret_mat.bits[y + 1]
    end
    ret_mat
end

function down_mat(mat::Mat, h::Int)::Mat
    ret_mat = copy(mat)
    for y in Iterators.countfrom(h, -1)
        if y == 1
            break
        end
        ret_mat.bits[y] |= ret_mat.bits[y - 1]
    end
    ret_mat
end

function left_mat(mat::Mat, h::Int64)::Mat
    ret_mat = copy(mat)
    for y in 1:h
        ret_mat.bits[y] >>= 1
    end
    ret_mat
end

function right_mat(mat::Mat, h::Int64)::Mat
    ret_mat = copy(mat)
    for y in 1:h
        ret_mat.bits[y] <<= 1
    end
    ret_mat
end

function print_multi_bit_set(bits::Vector{UInt64})
    for bit in bits
        println(
            lpad(
                lpad(string(bit, base=2), 7, "0"),
                50,
                " "
            )
        )
    end
    println()
end

function expand!(mat::Mat, h::Int)
    up = up_mat(mat, h)
    down = down_mat(mat, h)
    left = left_mat(mat, h)
    right = right_mat(mat, h)
    mat.bits .|= up.bits
    mat.bits .|= down.bits
    mat.bits .|= left.bits
    mat.bits .|= right.bits
end

function andeq_not!(mat1::Mat, mat2::Mat, h::Int64)
    for y in 1:h
        mat1.bits[y] &= ~mat2.bits[y]
    end
end

function is_equal(mat1::Mat, mat2::Mat, h::Int64)::Bool
    for y in 1:h
        if mat1.bits[y] != mat2.bits[y]
            return false
        end
    end
    true
end

function is_any_equal(mat1::Mat, mat2::Mat, h::Int64)::Bool
    for y in 1:h
        if mat1.bits[y] & mat2.bits[y] != 0
            return true
        end
    end
    false
end

mutable struct MazeStateByBitSet
    whole_point_mat::Mat
    walls::Mat
    base_state::WallMazeState

    function MazeStateByBitSet(state::WallMazeState, h::Int)
        whole_point_mat = Mat(h)
        walls = Mat(h)
        for y in 1:state.h
            for x in 1:state.w
                if state.walls[y, x] == 1
                    set!(walls, y, x)
                end
                if state.points[y, x] > 0
                    set!(whole_point_mat, y, x)
                end
            end
        end
        new(whole_point_mat, walls, state)
    end
end

function get_distance_to_nearest_point(state::MazeStateByBitSet)::Int
    now_mat = Mat(state.base_state.h)
    set!(now_mat, state.base_state.character.y, state.base_state.character.x)
    mask::UInt64 = 0x7f
    for depth in Iterators.countfrom(1)
        if is_any_equal(now_mat, state.whole_point_mat, state.base_state.h)
            return depth
        end
        next_mat = copy(now_mat)
        expand!(next_mat, state.base_state.h)
        next_mat.bits .&= mask
        andeq_not!(next_mat, state.walls, state.base_state.h)
        if is_equal(next_mat, now_mat, state.base_state.h)
            break
        end
        now_mat = next_mat
    end
    state.base_state.h * state.base_state.w
end

function evaluate!(state::WallMazeState, h::Int, w::Int)
    distance = get_distance_to_nearest_point(MazeStateByBitSet(state, h))
    state.evaluated_score = state.game_score * h * w - distance
end

function beam_search_action(state::WallMazeState, beam_width::Int, beam_depth::Int)::Int64

    now_beam = PriorityQueue{WallMazeState, Int64}(Base.Order.Reverse)
    push!(now_beam, state => state.evaluated_score)
    best_state = state
    hash_check = Set(Int[])
    for t in 1:beam_depth
        next_beam = PriorityQueue{WallMazeState, Int64}(Base.Order.Reverse)
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

function test_ai_score(ai::Pair, game_number::Int, h::Int, w::Int, end_turn::Int, base_hash::Hash)
    score_mean = 0.0
    for seed in 1:game_number
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
# ai = "bit_beam_search_agent" => state -> MultiBitSet.beam_search_action(state, beam_width, beam_depth)
# MultiBitSet.test_ai_score(ai, 100, h, w, end_turn, base_hash)
# MultiBitSet.test_ai_speed(ai, 100, 10, h, w, end_turn, base_hash)