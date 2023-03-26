include("./05_BeamSearchWithTime.jl")


module ChokudaiSearchAgent

using ..MazeGame: MazeState, legal_actions, advance!, to_string, is_done, evaluate_score!
using Distributed

function chokudai_search_action(state::MazeState, beam_width::Int, beam_depth::Int, beam_number::Int)::Int
    beam = Vector{MazeState}[]
    @sync @distributed for _ in 1:beam_depth+1
        push!(beam, MazeState[])
    end
    push!(beam[1], state)

    for bn in 1:beam_number
        for t in 1:beam_depth
            now_beam = beam[t]
            next_beam = beam[t + 1]
            for i in 1:beam_width
                if length(now_beam) == 0
                    break
                end
                now_state = now_beam[1]
                if is_done(now_state)
                    break
                end
                popfirst!(now_beam)

                la = legal_actions(now_state)
                @sync @distributed for action in la
                    next_state = deepcopy(now_state)
                    advance!(next_state, action)
                    if t == 1
                        next_state.first_action = action
                    end
                    evaluate_score!(next_state)
                    push!(next_beam, next_state)
                end
            end
            beam[t + 1] = sort(next_beam, by=state->state.evaluated_score, rev=true)
        end
    end

    for t in Iterators.countfrom(beam_depth + 1, -1)
        if length(beam[t]) > 0
            return beam[t][1].first_action
        end
    end

    return -1
end

end


# ai = "chokudai_search_agent" => state -> ChokudaiSearchAgent.chokudai_search_action(state, 1, 4, 2)
# AITester.test_ai_score(ai, 100)