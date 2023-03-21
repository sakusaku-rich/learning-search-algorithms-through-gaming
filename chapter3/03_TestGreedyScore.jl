include("01_Greedy.jl")

function test_ai_score(game_number::Int)
    score_mean = 0.0
    for seed in 1:game_number
        state = MazeState(seed, 3, 4, 4)
        while !is_done(state)
            advance!(state, greedy_action(state))
        end
        score_mean += state.game_score
    end
    score_mean /= game_number
    println("score mean: $(score_mean)")
end

test_ai_score(100)