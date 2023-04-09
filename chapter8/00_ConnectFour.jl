module ConnectFourGame

using DataStructures: Deque
using Random: rand, seed!

const H = 6
const W = 7
const DX = (1, -1)
const DY_RIGHT_UP = (1, -1)
const DY_LEFT_UP = (-1, 1)

@enum WinningStatus begin
    WIN
    LOSE
    DRAW
    NONE
end

mutable struct ConnectFourState
    is_first::Bool
    my_board::Matrix{Int}
    enemy_board::Matrix{Int}
    winning_status::WinningStatus

    function ConnectFourState()
        new(true, zeros(Int, H, W), zeros(Int, H, W), NONE)
    end

    function ConnectFourState(is_first, my_board, enemy_board, winning_status)
        new(is_first, my_board, enemy_board, winning_status)
    end
end

Base.copy(state::ConnectFourState) = ConnectFourState(state.is_first, copy(state.my_board), copy(state.enemy_board), state.winning_status)

function is_done(state::ConnectFourState)
    state.winning_status != NONE
end

function get_winning_status(state::ConnectFourState)
    state.winning_status
end



function legal_actions(state::ConnectFourState)::Vector{Int}
    actions = Int[]
    for x in 1:W
        for y in Iterators.countfrom(H, -1)
            if y == 0
                break
            end
            if state.my_board[y, x] == 0 && state.enemy_board[y, x] == 0
                push!(actions, x)
                break
            end
        end
    end
    actions
end

function advance!(state::ConnectFourState, action::Int)
    coordinate::Vector{Int} = []
    for y in 1:H
        if state.my_board[y, action] == 0 && state.enemy_board[y, action] == 0
            state.my_board[y, action] = 1
            coordinate = [y, action]
            break
        end
    end

    que = Deque{Vector{Int}}()
    push!(que, coordinate)
    check = falses(H, W)
    
    count = 0;
    while !isempty(que)
        tmp_cod = popfirst!(que)
        count += 1
        if count >= 4
            state.winning_status = LOSE
            break;
        end
        check[tmp_cod[1], tmp_cod[2]] = true;

        for action in 1:2
            ty = tmp_cod[1]
            tx = tmp_cod[2] + DX[action]

            if 1 <= ty <= H && 1 <= tx <= W && state.my_board[ty, tx] == 1 && !check[ty, tx]
                push!(que, [ty, tx])
            end
        end
    end

    if !is_done(state)
        que = Deque{Vector{Int}}()
        push!(que, coordinate)
        check = falses(H, W)
        count = 0;
        while !isempty(que)
            tmp_cod = popfirst!(que)
            count += 1
            if count >= 4
                state.winning_status = LOSE
                break;
            end
            check[tmp_cod[1], tmp_cod[2]] = true;

            for action in 1:2
                ty = tmp_cod[1] + DY_RIGHT_UP[action]
                tx = tmp_cod[2] + DX[action]

                if 1 <= ty <= H && 1 <= tx <= W && state.my_board[ty, tx] == 1 && !check[ty, tx]
                    push!(que, [ty, tx])
                end
            end
        end
    end

    if !is_done(state)
        que = Deque{Vector{Int}}()
        push!(que, coordinate)
        check = falses(H, W)
        count = 0;
        while !isempty(que)
            tmp_cod = popfirst!(que)
            count += 1
            if count >= 4
                state.winning_status = LOSE
                break;
            end
            check[tmp_cod[1], tmp_cod[2]] = true;

            for action in 1:2
                ty = tmp_cod[1] + DY_LEFT_UP[action]
                tx = tmp_cod[2] + DX[action]

                if 1 <= ty <= H && 1 <= tx <= W && state.my_board[ty, tx] == 1 && !check[ty, tx]
                    push!(que, [ty, tx])
                end
            end
        end
    end

    if !is_done(state)
        que = Deque{Vector{Int}}()
        push!(que, coordinate)
        check = falses(H, W)
        count = 0;
        while !isempty(que)
            tmp_cod = popfirst!(que)
            count += 1
            if count >= 4
                state.winning_status = LOSE
                break;
            end
            check[tmp_cod[1], tmp_cod[2]] = true;

            for action in 1:2
                ty = tmp_cod[1] + DY_RIGHT_UP[action]
                tx = tmp_cod[2]

                if 1 <= ty <= H && 1 <= tx <= W && state.my_board[ty, tx] == 1 && !check[ty, tx]
                    push!(que, [ty, tx])
                end
            end
        end
    end
    swap_board!(state)
    state.is_first = !state.is_first
    if state.winning_status == NONE && length(legal_actions(state)) == 0
        state.winning_status = DRAW
    end
end

function swap_board!(state::ConnectFourState)
    state.my_board, state.enemy_board = state.enemy_board, state.my_board
end

function to_string(state::ConnectFourState)::String
    ss = "\n"
    for y in Iterators.countfrom(H, -1)
        if y == 0
            break
        end
        for x in 1:W
            c = "."
            if state.my_board[y, x] == 1
                c = state.is_first ? "x" : "o"
            elseif state.enemy_board[y, x] == 1
                c = state.is_first ? "o" : "x"
            end
            ss *= c
        end
        ss *= "\n"
    end
    ss
end

function play_game(ais::Vector{Pair{String, Function}})
    seed!(0)
    state = ConnectFourState()
    println(to_string(state))
    while !is_done(state)
        println("1p ------------------------------------")
        action = ais[1].second(state)
        println("action: ", action)
        advance!(state, action)
        println(to_string(state))
        if is_done(state)
            winning_status = get_winning_status(state)
            if winning_status == WIN
                println("winner: 2p")
            elseif winning_status == LOSE
                println("winner: 1p")
            else
                println("DRAW")
            end
            break
        end
        
        println("2p ------------------------------------")
        action = ais[2].second(state)
        println("action: ", action)
        advance!(state, action)
        println(to_string(state))
        if is_done(state)
            winning_status = get_winning_status(state)
            if winning_status == WIN
                println("winner: 1p")
            elseif winning_status == LOSE
                println("winner: 2p")
            else
                println("DRAW")
            end
            break
        end
    end
end

end

module RandomAgent

using ..ConnectFourGame: ConnectFourState, legal_actions, advance!

function random_action(state::ConnectFourState)::Int64
    actions = legal_actions(state)
    actions[rand(1:length(actions))]
end

end

# ais::Vector{Pair{String, Function}} = [
#     "random_agent1" => state -> RandomAgent.random_action(state),
#     "random_agent2" => state -> RandomAgent.random_action(state)
# ]
# ConnectFourGame.play_game(ais)