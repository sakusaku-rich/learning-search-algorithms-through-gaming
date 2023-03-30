include("02_MCTSSimulation.jl")

module DUCTAgent

using ..SimultaneousMazeGame: legal_actions, SimultaneousMazeState, advance!, get_winning_status, FIRST, SECOND, DRAW, NONE, is_done
using ..RandomAgent: random_action
using ..AlternateMazeGame: AlternateMazeState

mutable struct Node
    state::SimultaneousMazeState
    w::Float64
    child_nodeses::Vector{Vector{Node}}
    n::Int

    function Node(state::SimultaneousMazeState)
        new(state, 0.0, Vector{Node}[], 0)
    end
end

function playout(state::SimultaneousMazeState)::Float64
    winning_status = get_winning_status(state)
    if winning_status == FIRST
        return 1.0
    elseif winning_status == SECOND
        return 0.0
    elseif winning_status == DRAW
        return 0.5
    else
        advance!(
            state, 
            random_action(state, 1),
            random_action(state, 2),
        )
        return playout(state)
    end
end

function expand!(node::Node)
    actions1 = legal_actions(node.state, 1)
    actions2 = legal_actions(node.state, 2)
    empty!(node.child_nodeses)
    for action1 in actions1
        push!(node.child_nodeses, Node[])
        for action2 in actions2
            push!(node.child_nodeses[end], Node(deepcopy(node.state)))
            advance!(node.child_nodeses[end][end].state, action1, action2)
        end
    end
end

function next_child_node(node::Node, c::Float64)::Node
    for child_nodes in node.child_nodeses
        for child_node in child_nodes
            if child_node.n == 0
                return child_node
            end
        end
    end
    t = 0
    for child_nodes in node.child_nodeses
        for child_node in child_nodes
            t += child_node.n
        end
    end
    
    best_is = [0, 0]
    
    best_value = -Inf
    for i in eachindex(node.child_nodeses)
        child_nodes = node.child_nodeses[i]
        w = 0
        n = 0
        for j in eachindex(child_nodes)
            child_node = child_nodes[j]
            w += child_node.w
            n += child_node.n
        end
        ubc1_value = w / n + c * sqrt(log(t) / n)
        if ubc1_value > best_value
            best_value = ubc1_value
            best_is[1] = i
        end
    end

    best_value = -Inf
    for j in eachindex(node.child_nodeses[1])
        w = 0
        n = 0
        for i in eachindex(node.child_nodeses)
            child_node = node.child_nodeses[i][j]
            w += child_node.w
            n += child_node.n
        end
        w = 1.0 - w
        ubc1_value = w / n + c * sqrt(log(t) / n)
        if ubc1_value > best_value
            best_value = ubc1_value
            best_is[2] = j
        end
    end
    node.child_nodeses[best_is[1]][best_is[2]]
end

function evaluate!(node::Node, expand_threshold::Int, c::Float64)::Float64
    if is_done(node.state)
        value = 0.5
        winning_status = get_winning_status(node.state)
        if winning_status == FIRST
            value = 1.0
        elseif winning_status == SECOND
            value = 0.0
        end
        node.w += value
        node.n += 1
        return value
    end

    if length(node.child_nodeses) == 0
        state_copy = deepcopy(node.state)
        value = playout(state_copy)
        node.w += value
        node.n += 1
        if node.n == expand_threshold
            expand!(node)
        end
        return value;
    else
        value = evaluate!(next_child_node(node, c), expand_threshold, c)
        node.w += value
        node.n += 1
        return value
    end
end

function duct_action(state::SimultaneousMazeState, player_id::Int, playout_number::Int, expand_threshold::Int, c::Float64)::Int
    root_node = Node(state)
    expand!(root_node)
    for i in 1:playout_number
        evaluate!(root_node, expand_threshold, c)
    end
    actions = legal_actions(state, player_id)
    i_size = length(root_node.child_nodeses)
    j_size = length(root_node.child_nodeses[1])

    if player_id == 1
        best_action_searched_number = 0
        best_action_index = 0
        for i in 1:i_size
            n = 0
            for j in 1:j_size
                n += root_node.child_nodeses[i][j].n
            end
            if n > best_action_searched_number
                best_action_searched_number = n
                best_action_index = i
            end
        end
        return actions[best_action_index]
    else
        best_action_searched_number = 0
        best_j = 0
        for j in 1:j_size
            n = 0
            for i in 1:i_size
                n += root_node.child_nodeses[i][j].n
            end
            if n > best_action_searched_number
                best_j = j
                best_action_searched_number = n
            end
        end
        return actions[best_j]
    end
end


end

ais = Pair{String, Function}[
    "duct_action" => (state::SimultaneousMazeGame.SimultaneousMazeState, player_id::Int) -> DUCTAgent.duct_action(state, player_id, 1000, 5, 1.0),
    "mcts_action" => (state::SimultaneousMazeGame.SimultaneousMazeState, player_id::Int) -> MCTSAgent.mcts_action(state, player_id, 1000, 5, 1.0),
]
FirstPlayerWinRateTester.test_first_player_win_rate(5, 5, 20, ais, 500)