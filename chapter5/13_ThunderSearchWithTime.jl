include("12_ThunderSearch.jl")

module ThunderSearchActionWithTimeThreshold

using ..AlternateMazeGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions
using ..RandomAction: random_action
using ..MCTSAction: Node, expand!
using ..Util: TimeKeeper, is_time_over
using ..ThunderSearchAction: next_child_node, evaluate!

function thunder_search_action_with_time_threshold(state::AlternateMazeState, time_threshold::Int)::Int
    root_node = Node(state)
    expand!(root_node)
    time_keeper = TimeKeeper(time_threshold)
    for cnt in Iterators.countfrom()
        if is_time_over(time_keeper)
            break
        end
        evaluate!(root_node)
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

module MCTSActionWithTimeThreshold
using ..AlternateMazeGame: AlternateMazeState, advance!, to_string, is_done, get_winning_status, legal_actions
using ..RandomAction: random_action
using ..MCTSAction: Node, expand!, next_child_node, playout
using ..Util: TimeKeeper, is_time_over

function mcts_action_with_time_threshold(state::AlternateMazeState, expand_threshold::Int, c::Float64, time_threshold::Int)::Int
    root_node = Node(state)
    expand!(root_node)
    time_keeper = TimeKeeper(time_threshold)
    for i in Iterators.countfrom()
        if is_time_over(time_keeper)
            break
        end
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

end


# time_threshold = 10
# expand_threshold = 10
# ais = [ 
#     "thunder_search_action_with_time_threshold 1ms" => (state) -> ThunderSearchActionWithTimeThreshold.thunder_search_action_with_time_threshold(state, time_threshold),
#     "mcts_action_with_time_threshold 1ms" => (state) -> MCTSActionWithTimeThreshold.mcts_action_with_time_threshold(state, expand_threshold, 1.0, time_threshold)
# ]
# TestFirstPlayerWinRate.test_first_player_win_rate(5, 5, 10, ais, 100)