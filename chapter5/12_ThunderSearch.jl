include("./11_PrintTree_3000.jl")

module ThunderSearchAction

using ..AlternateMazeStateGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions
using ..RandomAction: random_action
using ..MCTSAction: Node

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

function next_child_node(node::Node)::Node
    for child_node in node.child_nodes
        if child_node.n == 0
            return child_node
        end
    end
    t = 0
    for child_node in node.child_nodes
        t += child_node.n
    end
    best_value = -floatmax(Float64)
    best_action_index = -1
    for i in 1:length(node.child_nodes)
        child_node = node.child_nodes[i]
        thunder_value = 1.0 - child_node.w / child_node.n
        if thunder_value > best_value
            best_action_index = i
            best_value = thunder_value
        end
    end
    node.child_nodes[best_action_index]
end

function evaluate!(node::Node)::Float64
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
    if length(node.child_nodes) == 0
        value = get_score_rate(node.state)
        node.w += value
        node.n += 1
        expand!(node)
        return value
    else
        value = 1.0 - evaluate!(next_child_node(node))
        node.w += value
        node.n += 1
        return value
    end
end

function thunder_search_action(state::AlternateMazeState, playout_number::Int, is_print::Bool)::Int
    root_node = Node(state)
    expand!(root_node)
    for i in 1:playout_number
        evaluate!(root_node)
    end
    actions = legal_actions(state)
    best_action_searched_number = -1
    best_action_index = -1
    @assert length(actions) == length(root_node.child_nodes)
    for i in 1:length(actions)
        n = root_node.child_nodes[i].n
        if n > best_action_searched_number
            best_action_index = i
            best_action_searched_number = n
        end
    end
    called_cnt = false
    if is_print && !called_cnt
        print_tree(root_node)
    end
    called_cnt = true
    actions[best_action_index]
end

function print_tree(node::Node, depth::Int = 1)
    for (i, child_node) in enumerate(node.child_nodes)
        for j in 1:depth
            print("__")
        end
        println(" $(i)($(child_node.n))")
        if length(child_node.child_nodes) > 0
            print_tree(child_node, depth + 1)
        end
    end
end

function get_score_rate(state::AlternateMazeState)::Float64
    if state.characters[1].game_score + state.characters[2].game_score == 0
        return 0.0
    end
    state.characters[1].game_score / (state.characters[1].game_score + state.characters[2].game_score)
end

end

# ais = [ 
#     "thunder_search_action" => (state) -> ThunderSearchAction.thunder_search_action(state, 300, false),
#     "mcts_action" => (state) -> MCTSAction.mcts_action(state, 300, 10, 1.0),
# ]
# TestFirstPlayerWinRate.test_first_player_win_rate(5, 5, 10, ais, 100)