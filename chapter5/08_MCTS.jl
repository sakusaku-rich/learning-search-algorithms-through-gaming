include("./07_PrimitiveMontecarloPlayoutNumber.jl")

module MCTSAction

using ..AlternateMazeGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions
using ..RandomAction: random_action

mutable struct Node
    state::AlternateMazeState
    w::Float64
    child_nodes::Vector{Node}
    n::Int

    function Node(state::AlternateMazeState)
        new(state, 0.0, Node[], 0)
    end
end

function next_child_node(node::Node, c::Float64)::Node
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
        ucb1_value = 1.0 - child_node.w / child_node.n + c * sqrt(2.0 * log(t) / child_node.n)
        if ucb1_value > best_value
            best_action_index = i
            best_value = ucb1_value
        end
    end
    return node.child_nodes[best_action_index]
end

function expand!(node::Node)
    actions = legal_actions(node.state)
    empty!(node.child_nodes)
    for action in actions
        push!(
            node.child_nodes, 
            Node(
                deepcopy(node.state)
            )
        )
        advance!(node.child_nodes[lastindex(node.child_nodes)].state, action)
    end
end

function playout(state::AlternateMazeState)::Float64
    winning_status = get_winning_status(state)
    if winning_status == 1
        return 1.0
    elseif winning_status == 2
        return 0.0
    elseif winning_status == 0
        return 0.5
    else
        advance!(state, random_action(state))
        return 1.0 - playout(state)
    end
end

function evaluate!(node::Node, expand_threshold::Int, c::Float64)::Float64
    if is_done(node.state)
        value = 0.5
        winning_status = get_winning_status(node.state)
        if winning_status == 1
            value = 1.0
        elseif winning_status == 2
            value = 0.0
        end
        node.w += value
        node.n += 1
        return value
    end
    if isempty(node.child_nodes)
        state_copy = deepcopy(node.state)
        value = playout(state_copy)
        node.w += value
        node.n += 1
        if node.n == expand_threshold
            expand!(node)
        end
        return value
    else
        value = 1.0 - evaluate!(next_child_node(node, c), expand_threshold, c)
        node.w += value
        node.n += 1
        return value
    end
end

function mcts_action(state::AlternateMazeState, playout_number::Int, expand_threshold::Int, c::Float64)::Int
    root_node = Node(state)
    expand!(root_node)
    for i in 1:playout_number
        evaluate!(root_node, expand_threshold, c)
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
    actions[best_action_index]
end

end

# expand_threshold = 10
# c = 1.0
# ais = [
#     "mcts_action 3000" => state -> MCTSAction.mcts_action(state, 3000, expand_threshold, c),
#     "primitive_montecarlo_action 3000" => state -> PrimitiveMontecarloAction.primitive_montecarlo_action(state, 3000),
# ]
# TestFirstPlayerWinRate.test_first_player_win_rate(5, 5, 10, ais, 100)