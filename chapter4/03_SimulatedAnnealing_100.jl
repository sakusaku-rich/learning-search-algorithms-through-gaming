include("./02_SimulatedAnnealing.jl")

# simulate_number = 100
# ais = [
#     "hill_climb" => state -> HillClimbAgent.hill_climb(state, simulate_number),
#     "simulated_annealing" => state -> SimulatedAnnealingAgent.simulated_annealing(state, simulate_number, 500, 10)    
# ]
# game_number = 1000
# for ai in ais
#     AITester.test_ai_score(ai, game_number)
# end