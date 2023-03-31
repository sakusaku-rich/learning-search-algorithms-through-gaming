include("./04_BeamSearch.jl")


module Util

using Dates: now, Millisecond, DateTime

struct TimeKeeper
    start_time::DateTime
    time_threshold::Int
    function TimeKeeper(time_threshold::Int)
        new(now(), time_threshold)
    end
end

function is_time_over(time_keeper::TimeKeeper)::Bool
    now() - time_keeper.start_time > Millisecond(time_keeper.time_threshold)
end

end



module BeamSearchWithTimeThresholdAgent

using ..MazeGame: MazeState, advance!, to_string, is_done, legal_actions, evaluate_score!
using ..Util: TimeKeeper, is_time_over

function beam_search_action_with_time_threshold(state::MazeState, beam_width::Int, time_threshold::Int)::Int
    time_keeper = TimeKeeper(time_threshold)
    now_beam = [state]
    best_state = state
    for t in Iterators.countfrom()
        next_beam = []
        for i in 1:beam_width
            if is_time_over(time_keeper) && best_state.first_action != -1
                return best_state.first_action
            end
            if isempty(now_beam)
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


# ais = [
#     "beam_search_agent 1ms" => state -> BeamSearchWithTimeThresholdAgent.beam_search_action_with_time_threshold(state, 5, 1),
#     "beam_search_agent 10ms" => state -> BeamSearchWithTimeThresholdAgent.beam_search_action_with_time_threshold(state, 5, 10),
# ]
# println("1ms: ")
# AITester.test_ai_score(ais[1], 100)
# println("10ms: ")
# AITester.test_ai_score(ais[2], 100)