include("./03_TestGreedyScore.jl")


module BeamSearchAgent

using ..MazeGame: MazeState, legal_actions, advance!, to_string, is_done, evaluate_score!

function beam_search_action(state::MazeState, beam_width::Int, beam_depth::Int)::Int
    now_beam = [state]
    best_state = state
    for t in 1:beam_depth
        next_beam = []
        for i in 1:beam_width
            if length(now_beam) == 0
                break
            end
            now_state = popfirst!(now_beam)
            la = legal_actions(now_state)
            for action in la
                next_state = deepcopy(now_state)
                advance!(next_state, action)
                if t == 1
                    next_state.first_action = action
                end
                push!(next_beam, next_state)
            end
        end
        
        evaluate_score!.(next_beam)
        now_beam = sort(next_beam, by=state->state.evaluated_score, rev=true)
        best_state = now_beam[1]

        if is_done(best_state)
            break
        end
    end
    best_state.first_action
end

end

# ai = "beam_search_agent" => state -> BeamSearchAgent.beam_search_action(state, 10, 4)
# AITester.test_ai_score(ai, 100)