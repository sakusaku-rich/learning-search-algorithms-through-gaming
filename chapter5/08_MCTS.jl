using Random: seed!, rand
using Dates: now, Millisecond, DateTime

const H = 5
const W = 5
const END_TURN = 10
const DX = [-1, 1, 0, 0]
const DY = [0, 0, 1, -1]
const C = 1.0
const EXPAND_THRESHOLD = 10


mutable struct Character
    x::Int
    y::Int
    game_score::Int

    function Character(x::Int, y::Int, game_score::Int=0)
        new(x, y, game_score)
    end
end


mutable struct AlternateMazeState
    points::Matrix{Int}
    turn::Int
    characters::Vector{Character}

    function AlternateMazeState(
        seed::Int, 
        characters::Vector{Character} = Character[
            Character(Int(floor(H / 2)), Int(floor(W / 2))-1, 0),
            Character(Int(ceil(H / 2)), Int(ceil(W / 2))+1, 0),
        ]
    )
        seed!(seed)
        points = zeros(Int, H, W)
        for y in 1:H
            for x in 1:W
                point = rand(0:9)
                if characters[1].x == x && characters[1].y == y
                    continue
                end
                if characters[2].x == x && characters[2].y == y
                    continue
                end
                points[y, x] = point
            end
        end
        new(points, 0, characters)
    end
end

struct TimeKeeper
    start_time::DateTime
    time_threshold::Int
    function TimeKeeper(time_threshold::Int)
        new(now(), time_threshold)
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

function is_time_over(time_keeper::TimeKeeper)::Bool
    now() - time_keeper.start_time > Millisecond(time_keeper.time_threshold)
end

function is_done(state::AlternateMazeState)::Bool
    state.turn == END_TURN
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
    swap_characters!(state.characters)
end

function swap_characters!(characters::Vector{Character})
    push!(characters, popfirst!(characters))
end

function legal_actions(state::AlternateMazeState)::Vector{Int}
    actions = Int[]
    character = state.characters[1]
    for action in 1:4
        tx = character.x + DX[action]
        ty = character.y + DY[action]
        if tx >= 1 && tx <= W && ty >= 1 && ty <= H
            push!(actions, action)
        end
    end
    actions
end

function get_winning_status(state::AlternateMazeState)::Int
    if is_done(state)
        if state.characters[1].game_score > state.characters[2].game_score
            return 1
        elseif state.characters[1].game_score < state.characters[2].game_score
            return 2
        else
            return 0
        end
    else
        return -1
    end
end

function to_string(state::AlternateMazeState)::String
    s = ""
    for player_id in 1:length(state.characters)
        if state.turn % 2 == 1
            player_id = (player_id % 2) + 1
        end
        character = state.characters[player_id]
        s *= "Player $(player_id): $(character.game_score) ($(character.x), $(character.y))\n"
    end
    for h in 1:H
        for w in 1:W
            is_writeen = false
            for player_id in 1:length(state.characters)
                if state.turn % 2 == 1
                    player_id = (player_id % 2) + 1
                end
                character = state.characters[player_id]
                if character.x == h && character.y == w
                    if player_id == 1
                        s *= "A "
                    else
                        s *= "B "
                    end
                    is_writeen = true
                end
            end
            if !is_writeen
                if state.points[h, w] == 0
                    s *= ". "
                else
                    s *= string(state.points[h, w]) * " "
                end
            end
        end
        s *= "\n\n"
    end
    s
end

function random_action(state::AlternateMazeState)::Int
    rand(legal_actions(state))
end

function get_score(state::AlternateMazeState)::Int
    state.characters[1].game_score - state.characters[2].game_score
end

function mini_max_score(state::AlternateMazeState, depth::Int)::Int
    if is_done(state) || depth == 0
        return get_score(state)
    end
    actions = legal_actions(state)
    if length(actions) == 0
        return get_score(state)
    end
    best_score = -typemax(Int)
    for action in actions
        next_state = deepcopy(state)
        advance!(next_state, action)
        score = -mini_max_score(next_state, depth - 1)
        if score > best_score
            best_score = score
        end
    end
    best_score
end

function mini_max_action(state::AlternateMazeState, depth::Int)::Int
    best_action = -1
    best_score = -typemax(Int)
    for action in legal_actions(state)
        next_state = deepcopy(state)
        advance!(next_state, action)
        score = -mini_max_score(next_state, depth - 1)
        if score > best_score
            best_score = score
            best_action = action
        end
    end
    best_action
end

function is_first_player(state::AlternateMazeState)::Bool
    state.turn % 2 == 0
end

function get_first_player_score_for_win_rate(state::AlternateMazeState)::Float64
    winnnig_status = get_winning_status(state)
    if winnnig_status == 1
        if is_first_player(state)
            return 1.0
        else
            return 0.0
        end
    elseif winnnig_status == 2
        if is_first_player(state)
            return 0.0
        else
            return 1.0
        end
    else
        return 0.5
    end
end

function test_first_player_win_rate(ais::Vector{Pair{String, Function}}, game_number::Int)
    first_player_win_rate = 0.0
    for seed in 1:game_number
        base_state = AlternateMazeState(seed)
        for j in [1,2]
            state = deepcopy(base_state)
            first_ai = ais[j]
            second_ai = ais[j % 2 + 1]
            while true
                advance!(state, first_ai.second(state))
                if is_done(state)
                    break
                end
                advance!(state, second_ai.second(state))
                if is_done(state)
                    break
                end
            end
            win_rate_point = get_first_player_score_for_win_rate(state)
            if j == 2
                win_rate_point = 1.0 - win_rate_point
            end
            first_player_win_rate += win_rate_point
        end
        println("seed: $(seed) win_rate: $(first_player_win_rate / (2 * seed))")
    end
    first_player_win_rate /= 2 * game_number
    println("Winnig rate of $(ais[1].first) to $(ais[2].first):\t$(first_player_win_rate)")
end


function play_game(seed::Int)
    state = AlternateMazeState(seed)
    while !is_done(state)
        println("1p ----")
        action = mini_max_action(state, END_TURN)
        println("action: $(action)")
        advance!(state, action)
        println(to_string(state))
        if is_done(state)
            if get_winning_status(state) == 1
                println("winner: 1p")
                break
            elseif get_winning_status(state) == 2
                println("winner: 2p")
                break
            else
                println("DRAW")
                break
            end
        end
        println("2p ----")
        action = random_action(state)
        println("action: $(action)")
        advance!(state, action)
        println(to_string(state))
        if is_done(state)
            if get_winning_status(state) == 1
                println("winner: 1p")
                break
            elseif get_winning_status(state) == 2
                println("winner: 2p")
                break
            else
                println("DRAW")
                break
            end
        end
    end
end

function alpha_beta_score(state::AlternateMazeState, alpha::Int, beta::Int, depth::Int, time_keeper::TimeKeeper)::Int
    if is_time_over(time_keeper)
        return 1
    end
    if is_done(state) || depth == 0
        return get_score(state)
    end
    actions = legal_actions(state)
    if length(actions) == 0
        return get_score(state)
    end
    for action in actions        
        next_state = deepcopy(state)
        advance!(next_state, action)
        score = -alpha_beta_score(next_state, -beta, -alpha, depth - 1, time_keeper)
        if score > alpha
            alpha = score
        end
        if alpha >= beta
            return alpha
        end
        if is_time_over(time_keeper)
            return 1
        end
    end
    alpha
end

function alpha_beta_action_with_time_threshold(state::AlternateMazeState, depth::Int, time_keeper::TimeKeeper)::Int
    best_action = -1
    alpha = -typemax(Int)
    beta = typemax(Int)
    for action in legal_actions(state)
        next_state = deepcopy(state)
        advance!(next_state, action)
        score = -alpha_beta_score(next_state, -beta, -alpha, depth, time_keeper)
        if score > alpha
            best_action = action
            alpha = score
        end
        if is_time_over(time_keeper)
            return 1
        end
    end
    best_action
end

function iterative_deepening_action(state::AlternateMazeState, time_threshold::Int)::Int
    time_keeper = TimeKeeper(time_threshold)
    best_action = -1
    for depth in Iterators.countfrom()
        action = alpha_beta_action_with_time_threshold(state, depth, time_keeper)
        if is_time_over(time_keeper)
            break
        else
            best_action = action
        end
    end
    best_action
end

function get_sample_states(game_number::Int)::Vector{AlternateMazeState}
    states = []
    for seed in 1:game_number
        seed!(seed)
        state = AlternateMazeState(seed)
        turn = rand(1:END_TURN)
        for t in 1:turn
            advance!(state, random_action(state))
        end
        push!(states, state)
    end
    states
end

function calculate_execution_speed(ai::Pair, states::Vector{AlternateMazeState})
    start_time = now()
    for state in states
        ai.second(state)
    end
    diff = now() - start_time
    println("$(ai.first) take $(diff) ms to process $(length(states)) nodes")
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

function primitive_montecarlo_action(state::AlternateMazeState, playout_number::Int)::Int
    actions = legal_actions(state)
    values = repeat([0.0], length(actions))
    cnts = repeat([0], length(actions))
    for cnt in 1:playout_number
        index = mod(cnt, length(actions)) + 1
        next_state = deepcopy(state)
        advance!(next_state, actions[index])
        values[index] += 1.0 - playout(next_state)
        cnts[index] += 1
    end
    best_action_index = -1
    best_score = -floatmax(Float64)
    for index in 1:length(actions)
        value_mean = values[index] / cnts[index]
        if value_mean > best_score
            best_score = value_mean
            best_action_index = index
        end
    end
    actions[best_action_index]
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

function next_child_node(node::Node)::Node
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
    for i in 1:length(node.child_nodes)
        child_node = node.child_nodes[i]
        ucb1_value = 1.0 - child_node.w / child_node.n + C * sqrt(2.0 * log(t) / child_node.n)
        if ucb1_value > best_value
            best_action_index = i
            best_value = ucb1_value
        end
    end
    return node.child_nodes[best_action_index]
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
        state_copy = deepcopy(node.state)
        value = playout(state_copy)
        node.w += value
        node.n += 1
        if node.n == EXPAND_THRESHOLD
            expand!(node)
        end
        return value
    else
        value = 1.0 - evaluate!(next_child_node(node))
        node.w += value
        node.n += 1
        return value
    end
end

function mcts_action(state::AlternateMazeState, playout_number::Int)::Int
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
    actions[best_action_index]
end

ais = [
    "mcts_action 3000" => state -> mcts_action(state, 3000),
    "primitive_montecarlo_action 3000" => state -> primitive_montecarlo_action(state, 3000),
]
test_first_player_win_rate(ais, 100)