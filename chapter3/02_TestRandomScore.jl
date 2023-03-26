include("./01_Greedy.jl")

module AITester

using ..MazeGame: MazeState, legal_actions, advance!, to_string, is_done, evaluate_score!
using ..RandomAgent: random_action
using Distributed

function test_ai_score(ai::Pair, game_number::Int)
    score_mean = 0.0
    @sync @distributed for seed in 1:game_number
        state = MazeState(seed, 3, 4, 4)
        while !is_done(state)
            advance!(state, ai.second(state))
        end
        score_mean += state.game_score
    end
    score_mean /= game_number
    println("score mean: $(score_mean)")
end

end

# ai = "random_agent" => state -> RandomAgent.random_action(state)
# AITester.test_ai_score(ai, 100)