include("13_ThunderSearchWithTime.jl")


# time_threshold = 10
# expand_threshold = 10
# ais = [ 
#     "thunder_search_action_with_time_threshold 1ms" => (state) -> ThunderSearchActionWithTimeThreshold.thunder_search_action_with_time_threshold(state, time_threshold),
#     "iterative_deepening_action 1ms" => (state) -> IterativeDeepeningAction.iterative_deepening_action(state, time_threshold)
# ]
# TestFirstPlayerWinRate.test_first_player_win_rate(5, 5, 10, ais, 100)