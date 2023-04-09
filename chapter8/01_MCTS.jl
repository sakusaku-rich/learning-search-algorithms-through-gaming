include("00_ConnectFour.jl")

module Util

using Dates: now, Millisecond, DateTime

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

end

module MCTSAgent
using Random: rand, seed!
using ..ConnectFourGame: ConnectFourState, advance!, to_string, is_done, get_winning_status, legal_actions, WIN, LOSE, DRAW, NONE
using ..RandomAgent: random_action
using ..Util: TimeKeeper, is_time_over

const C = 1.0
const EXPAND_THRESHOLD = 10

mutable struct Node
    state::ConnectFourState
    child_nodes::Vector{Node}
    w::Float64
    n::Int
    function Node(state::ConnectFourState)
        new(state, Node[], 0.0, 0)
    end
end

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
            Node(
                copy(node.state)
            )
        )
        advance!(node.child_nodes[lastindex(node.child_nodes)].state, action)
    end
end

function playout(state::ConnectFourState)::Float64
    winning_status = get_winning_status(state)
    if winning_status == WIN
        return 1.0
    elseif winning_status == LOSE
        return 0.0
    elseif winning_status == DRAW
        return 0.5
    else
        advance!(state, random_action(state))
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

function mcts_action_with_time_threshold(state::ConnectFourState, time_threshold::Int)::Int
    root_node = Node(state)
    expand!(root_node)
    time_keeper = TimeKeeper(time_threshold)
    for cnt in Iterators.countfrom(1)
        evaluate!(root_node)
        is_time_over(time_keeper) && break
    end

    actions = legal_actions(state)
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

module AITester

using Random: seed!
using ..ConnectFourGame: ConnectFourState, advance!, to_string, is_done, get_winning_status, legal_actions, WIN, LOSE, DRAW, NONE

function get_first_player_score_for_win_rate(state::ConnectFourState)::Float64
    winning_status = get_winning_status(state)
    if winning_status == WIN
        if state.is_first
            return 1.0
        else
            return 0.0
        end
    elseif winning_status == LOSE
        if state.is_first
            return 0.0
        else
            return 1.0
        end
    elseif winning_status == DRAW
        return 0.5
    end
end

function test_first_player_win_rate(ais::Vector{Pair{String, Function}}, game_number::Int, verbose::Bool=false)
    first_player_win_rate = 0.0
    for i in 1:game_number
        seed!(i)
        best_state = ConnectFourState()
        for j in 1:2
            state = best_state
            first_ai = ais[j]
            second_ai = ais[(j % 2) + 1]
            for k in Iterators.countfrom(1)
                action = first_ai.second(state)
                advance!(state, action)
                if is_done(state)
                    break
                end
                action = second_ai.second(state)
                advance!(state, action)
                if is_done(state)
                    break
                end
            end

            win_rate_point = get_first_player_score_for_win_rate(state)
            if j == 2
                win_rate_point = 1.0 - win_rate_point
            end
            if win_rate_point >= 0.0 && verbose
                println(to_string(state))
            end
            first_player_win_rate += win_rate_point
        end
        println("i $(i)\tw $(first_player_win_rate / (i * 2))")
    end
    first_player_win_rate /= game_number * 2
    println("Winning rate of $(ais[1].first) to $(ais[2].first) :\t $(first_player_win_rate)")
end

end


# ais::Vector{Pair{String, Function}} = [
#     "mcts_agent" => state -> MCTSAgent.mcts_action_with_time_threshold(state, 1),
#     "random_agent" => state -> RandomAgent.random_action(state)
# ]
# AITester.test_first_player_win_rate(ais, 100)