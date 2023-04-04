include("./03_TestGreedyScore.jl")


module BeamSearchAgent

using ..MazeGame: MazeState, legal_actions, advance!, to_string, is_done, evaluate_score!
using DataStructures: PriorityQueue, dequeue!

function beam_search_action(state::MazeState, beam_width::Int, beam_depth::Int)::Int
    now_beam = PriorityQueue{MazeState, Int}(Base.Order.Reverse)
    push!(now_beam, state => state.evaluated_score)
    best_state = state
    for t in 1:beam_depth
        next_beam = PriorityQueue{MazeState, Int}(Base.Order.Reverse)
        for i in 1:beam_width
            if isempty(now_beam)
                break
            end
            now_state = dequeue!(now_beam)
            la = legal_actions(now_state)
            for action in la
                next_state = deepcopy(now_state)
                advance!(next_state, action)
                if t == 1
                    next_state.first_action = action
                end
                evaluate_score!(next_state)
                push!(next_beam, next_state => next_state.evaluated_score)
            end
        end
        now_beam = next_beam
        best_state = first(now_beam)[1]
        if is_done(best_state)
            break
        end
    end
    best_state.first_action
end

end

# ai = "beam_search_agent" => state -> BeamSearchAgent.beam_search_action(state, 10, 4)
# AITester.test_ai_score(ai, 100)