include("./00_AutoMoveMazeState.jl")

module HillClimbAgent

using ..AutoMoveMazeGame: AutoMoveMazeState, get_score, CHARACTER_N, H, W, init!, transition!

function hill_climb(state::AutoMoveMazeState, number::Int)
    now_state = copy(state)
    init!(now_state)
    best_score = get_score(now_state, false)
    for i in 1:number
        next_state = copy(now_state)
        transition!(next_state)
        next_score = get_score(next_state, false)
        if next_score > best_score
            best_score = next_score
            now_state = next_state
        end
    end
    now_state
end

end

# ai = "hill_climb" => state -> HillClimbAgent.hill_climb(state, 10000)
# AutoMoveMazeGame.play_game(ai, 0)