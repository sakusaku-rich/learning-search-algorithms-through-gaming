include("./01_HillClimb.jl")

module SimulatedAnnealingAgent
using ..AutoMoveMazeGame: AutoMoveMazeState, get_score, CHARACTER_N, H, W, init!, transition!

function simulated_annealing(state::AutoMoveMazeState, number::Int, start_temp::Int, end_temp::Int)
    now_state = copy(state)
    init!(now_state)
    best_score = get_score(now_state, false)
    now_score = best_score
    best_state = now_state
    for i in 1:number
        next_state = copy(now_state)
        transition!(next_state)
        next_score = get_score(next_state, false)
        temp = start_temp + (end_temp - start_temp) * (i / number)
        probability = exp((next_score - now_score) / temp)
        is_force_next = probability > rand()
        if next_score > best_score || is_force_next
            now_score = next_score
            now_state = next_state
        end
        if next_score > best_score
            best_score = next_score
            best_state = next_state
        end

    end
    best_state
end

end

module AITester
using ..AutoMoveMazeGame: AutoMoveMazeState, get_score
function test_ai_score(ai::Pair{String, Function}, game_number::Int)
    score_mean = 0.0
    for i in 1:game_number
        state = AutoMoveMazeState(i)
        state = ai.second(state)
        score = get_score(state, false)
        score_mean += score
    end
    score_mean /= game_number
    println("Score of $(ai.first): $(score_mean)")
end
end

# simulate_number = 10000
# ais = [
#     "hill_climb" => state -> HillClimbAgent.hill_climb(state, simulate_number),
#     "simulated_annealing" => state -> SimulatedAnnealingAgent.simulated_annealing(state, simulate_number, 500, 10)    
# ]
# game_number = 1000
# for ai in ais
#     AITester.test_ai_score(ai, game_number)
# end