include("01_PrimitiveMontecarlo.jl")

module AlternateMazeGame

using ..SimultaneousMazeGame: SimultaneousMazeState, Character, WinningStatus, FIRST, SECOND, DRAW, NONE, DX, DY

mutable struct AlternateMazeState
    end_turn::Int
    points::Matrix{Int}
    turn::Int
    characters::Vector{Character}
    w::Int
    h::Int

    function AlternateMazeState(base_state::SimultaneousMazeState, player_id::Int)
        new(
            base_state.end_turn * 2, 
            base_state.points, 
            base_state.turn * 2, 
            player_id == 1 ? base_state.characters : reverse(base_state.characters),
            base_state.w,
            base_state.h,
        )
    end
end

function is_done(state::AlternateMazeState)::Bool
    state.turn == state.end_turn
end

function get_winning_status(state::AlternateMazeState)::WinningStatus
    if is_done(state)
        if state.characters[1].game_score > state.characters[2].game_score
            return FIRST
        elseif state.characters[1].game_score < state.characters[2].game_score
            return SECOND
        else
            return DRAW
        end
    else
        return NONE
    end
end

function advance!(state::AlternateMazeState, action::Int)
    character = state.characters[1]
    character.x += DX[action]
    character.y += DY[action]
    point = state.points[character.y, character.x]
    if point > 0
        character.game_score += point
        state.points[character.y, character.x] = 0
    end
    state.turn += 1
    reverse!(state.characters)
end

function legal_actions(state::AlternateMazeState)::Vector{Int}
    player_id = 1
    actions = []
    for i in 1:4
        x = state.characters[player_id].x + DX[i]
        y = state.characters[player_id].y + DY[i]
        if 1 <= x <= state.w && 1 <= y <= state.h
            push!(actions, i)
        end
    end
    actions
end

end



module AlternateMontecarloAgent

using ..SimultaneousMazeGame: SimultaneousMazeState
using ..AlternateMazeGame: AlternateMazeState, legal_actions, advance!, is_done, get_winning_status, FIRST, SECOND, DRAW, NONE

function random_action(state::AlternateMazeState)::Int
    rand(legal_actions(state))    
end

function playout(state::AlternateMazeState)::Float64
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
            random_action(state),
        )
        return 1.0 - playout(state)
    end
end

mutable struct Node
    state::AlternateMazeState
    w::Float64
    child_nodes::Vector{Node}
    n::Int

    function Node(state::AlternateMazeState)
        new(state, 0.0, Node[], 0)
    end
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

    if length(node.child_nodes) == 0
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

function expand!(node::Node)
    empty!(node.child_nodes)
    for action in legal_actions(node.state)
        push!(node.child_nodes, Node(deepcopy(node.state)))
        advance!(node.child_nodes[lastindex(node.child_nodes)].state, action)
    end
end

function next_child_node(node::Node, c::Float64)::Node
    for child_node in node.child_nodes
        if child_node.n == 0
            return child_node
        end
    end
    t = 0
    for child_node in node.child_nodes
        t += child_node.n
    end
    best_value = -Inf
    best_action_index = -1
    for (i, child_node) in enumerate(node.child_nodes)
        ucb1_value = 1.0 - child_node.w / child_node.n + c * sqrt(2.0 * log(t) / child_node.n)
        if ucb1_value > best_value
            best_action_index = i
            best_value = ucb1_value
        end
    end
    node.child_nodes[best_action_index]
end

function mcts_action(base_state::SimultaneousMazeState, player_id::Int, playout_number::Int, expand_threshold::Int, c::Float64)::Int
    state = AlternateMazeState(base_state, player_id)
    root_node = Node(state)
    expand!(root_node)
    for _ in 1:playout_number
        evaluate!(root_node, expand_threshold, c)
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
    actions[best_action_index]
end

end

ais = Pair{String, Function}[
    "mcts_action" => (state::SimultaneousMazeGame.SimultaneousMazeState, player_id::Int) -> AlternateMontecarloAgent.mcts_action(state, player_id, 1000, 10, 1.0),
    "primitive_montecarlo_action" => (state::SimultaneousMazeGame.SimultaneousMazeState, player_id::Int) -> PrimitiveMontecarloAgent.primitive_montecarlo_action(state, player_id, 1000)
]
FirstPlayerWinRateTester.test_first_player_win_rate(5, 5, 20, ais, 500)