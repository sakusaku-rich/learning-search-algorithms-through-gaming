include("01_MCTS.jl")

module BitSetStateWrapper

using ..ConnectFourGame: ConnectFourState, WIN, LOSE, DRAW, NONE, WinningStatus, H, W

mutable struct ConnectFourStateByBitSet
    my_board::UInt64
    all_board::UInt64
    is_first::Bool
    winning_status::WinningStatus

    function ConnectFourStateByBitSet(state::ConnectFourState)
        my_board::UInt64 = 0
        all_board::UInt64 = 0
        for y in 1:H
            for x in 1:W
                index = (x - 1) * (H + 1) + (y - 1)
                if state.my_board[y, x] == 1
                    my_board |= 1 << index
                end
                if state.my_board[y, x] == 1 || state.enemy_board[y, x] == 1
                    all_board |= 1 << index
                end
            end
        end
        new(my_board, all_board, state.is_first, state.winning_status)
    end

    function ConnectFourStateByBitSet(my_board::UInt64, all_board::UInt64, is_first::Bool, winning_status::WinningStatus)
        new(my_board, all_board, is_first, winning_status)
    end
end

Base.copy(state::ConnectFourStateByBitSet) = ConnectFourStateByBitSet(state.my_board, state.all_board, state.is_first, state.winning_status)

function print_bit_board(bit_board::UInt64)
    pad = (H + 1) * (W + 1)
    str = lpad(string(bit_board, base=2), pad, "0")
    for y in 1:H+1
        for x in 1:W+1
            idx = x * (H + 1) - y
            idx = (H + 1) * (W + 1) - idx
            print(str[idx] * " ")
        end
    end
end

function legal_actions(state::ConnectFourStateByBitSet)::Vector{Int}
    actions = Int[]
    possible::UInt64 = state.all_board + 0b0000001000000100000010000001000000100000010000001
    filter::UInt64 = 0b0111111
    for x in 1:W
        if filter & possible != 0
            push!(actions, x)
        end
        filter <<= 7
    end
    actions
end

function is_winner(board::UInt64)::Bool
    tmp_board = board & (board >> 7)
    if (tmp_board & (tmp_board >> 14)) != 0
        return true
    end
    tmp_board = board & (board >> 6)
    if (tmp_board & (tmp_board >> 12)) != 0
        return true
    end
    tmp_board = board & (board >> 8)
    if (tmp_board & (tmp_board >> 16)) != 0
        return true
    end
    tmp_board = board & (board >> 1);
    if (tmp_board & (tmp_board >> 2)) != 0
        return true
    end
    false
end

function advance!(state::ConnectFourStateByBitSet, action::Int)
    state.my_board ⊻= state.all_board
    state.is_first = !state.is_first
    state.all_board |= (state.all_board + (1 << ((action - 1) * 7)))
    filled::UInt64 = 0b0111111011111101111110111111011111101111110111111
    state.all_board &= filled
    if is_winner(state.my_board ⊻ state.all_board)
        state.winning_status = LOSE
    elseif state.all_board == filled
        state.winning_status = DRAW
    end
end

end




module MCTSAgentBitVer
using Random: rand, seed!
using ..ConnectFourGame: ConnectFourState, WIN, LOSE, DRAW, NONE, WinningStatus, H, W
using ..RandomAgent: random_action
using ..Util: TimeKeeper, is_time_over
using ..BitSetStateWrapper: ConnectFourStateByBitSet, advance!, print_bit_board
import ..BitSetStateWrapper.legal_actions
using ..ConnectFourGame


const C = 1.0
const EXPAND_THRESHOLD = 10

mutable struct Node
    state::ConnectFourStateByBitSet
    child_nodes::Vector{Node}
    w::Float64
    n::Int
    function Node(state::ConnectFourStateByBitSet)
        new(state, Node[], 0.0, 0)
    end

    function Node(node::Node)
        new(copy(node.state), node.child_nodes, node.w, node.n)
    end
end

Base.copy(nodes::Vector{Node}) = Node.(nodes)

function next_child_nodes(node::Node)::Node
    for child_node in node.child_nodes
        if child_node.n == 0
            return child_node
        end
    end
    t = 0.0
    for child_node in node.child_nodes
        t += child_node.n
    end
    best_value = -floatmax(Float64)
    best_action_index = -1
    for i in eachindex(node.child_nodes)
        child_node = node.child_nodes[i]
        ucb1_value = 1.0 - child_node.w / child_node.n + C * sqrt(2.0 * log(t) / child_node.n)
        if ucb1_value > best_value
            best_action_index = i
            best_value = ucb1_value
        end
    end
    node.child_nodes[best_action_index]
end

function expand!(node::Node)
    actions = legal_actions(node.state)
    empty!(node.child_nodes)
    for action in actions
        push!(
            node.child_nodes,
            Node(copy(node.state))
        )
        advance!(node.child_nodes[end].state, action)
    end
end

function random_action_bit(state::ConnectFourStateByBitSet)::Int
    actions = legal_actions(state)
    actions[rand(1:length(actions))]
end

function playout(state::ConnectFourStateByBitSet)::Float64
    winning_status = get_winning_status(state)
    if winning_status == WIN
        return 1.0
    elseif winning_status == LOSE
        return 0.0
    elseif winning_status == DRAW
        return 0.5
    else
        advance!(state, random_action_bit(state))
        return 1.0 - playout(state)
    end
end

function evaluate!(node::Node)::Float64
    if is_done(node.state)
        value = 0.5
        winning_status = get_winning_status(node.state)
        if winning_status == WIN
            value = 1.0
        elseif winning_status == LOSE
            value = 0.0
        end
        node.w += value
        node.n += 1
        return value
    end
    if isempty(node.child_nodes)
        state_copy = copy(node.state)
        value = playout(state_copy)
        node.w += value
        node.n += 1
        if node.n == 1
            expand!(node)
        end
        return value
    else
        value = 1.0 - evaluate!(next_child_nodes(node))
        node.w += value
        node.n += 1
        return value
    end
end

function is_done(state::ConnectFourStateByBitSet)::Bool
    get_winning_status(state) != NONE
end

function get_winning_status(state::ConnectFourStateByBitSet)::WinningStatus
    state.winning_status
end

function mcts_action_with_time_threshold(state::ConnectFourState, time_threshold::Int)::Int
    bit_state = ConnectFourStateByBitSet(copy(state))
    root_node = Node(bit_state)

    expand!(root_node)
    time_keeper = TimeKeeper(time_threshold)
    for cnt in Iterators.countfrom(1)
        is_time_over(time_keeper) && break
        evaluate!(root_node)
    end

    actions = ConnectFourGame.legal_actions(state)
    best_action_searched_number = -1
    best_action_index = -1
    @assert length(actions) == length(root_node.child_nodes)
    for i in eachindex(actions)
        n = root_node.child_nodes[i].n
        if n > best_action_searched_number
            best_action_index = i
            best_action_searched_number = n
        end
    end
    actions[best_action_index];
end

end

# ais::Vector{Pair{String, Function}} = [
#     "mcts_agent_bit 1ms" => state -> MCTSAgentBitVer.mcts_action_with_time_threshold(state, 1),    
#     "mcts_agent 1ms" => state -> MCTSAgent.mcts_action_with_time_threshold(state, 1)
# ]
# AITester.test_first_player_win_rate(ais, 100)