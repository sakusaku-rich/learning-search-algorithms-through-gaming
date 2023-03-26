
include("./08_MCTS.jl")

# expand_threshold = 10
# c = 1.0
# ais = [
#     "mcts_action 3000" => state -> MCTSAction.mcts_action(state, 3000, expand_threshold, c),
#     "mcts_action 30" => state -> MCTSAction.mcts_action(state, 30, expand_threshold, c),
# ]
# TestFirstPlayerWinRate.test_first_player_win_rate(5, 5, 10, ais, 100)