include("./07_ChokudaiSearchWithTime.jl")

module BeamSearchByNthElementAgent

using ..MazeGame: MazeState, legal_actions, advance!, to_string, is_done, evaluate_score!

function beam_search_action_by_nth_element(state::MazeState, beam_width::Int, beam_depth::Int)::Int
    now_beam = [state]
    best_state = state
    for t in 1:beam_depth
        next_beam = []

        for nb in now_beam
            la = legal_actions(nb)
            for action in la
                next_state = deepcopy(nb)
                advance!(next_state, action)
                if t == 1
                    next_state.first_action = action
                end
                push!(next_beam, next_state)
            end
        end
        
        evaluate_score!.(next_beam)
        now_beam = sort(next_beam, by=state->state.evaluated_score, rev=true)
        if length(now_beam) > beam_width
            now_beam = now_beam[1:beam_width]
        end
        best_state = now_beam[1]
        if is_done(best_state)
            break
        end
        next_beam = now_beam
    end
    for nb in now_beam
        if nb.evaluated_score > best_state.evaluated_score
            best_state = nb
        end
    end
    best_state.first_action
end

end


# ai = "beam_search_by_nth_element_agent" => state -> BeamSearchByNthElementAgent.beam_search_action_by_nth_element(state, 10, 4)
# AITester.test_ai_score(ai, 100)