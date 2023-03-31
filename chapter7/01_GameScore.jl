include("00_WallMazeState.jl")

module BeamSearchAgent
using ..WallMazeGame: WallMazeState, Coord, DX, DY, legal_actions, advance!, is_done, evaluate!

function beam_search_action(state::WallMazeState, beam_width::Int, beam_depth::Int)
    now_beam = WallMazeState[state]
    best_state = state
    for t in 1:beam_depth
        next_beam = WallMazeState[]
        for i in beam_width
            if isempty(now_beam)
                break
            end
            now_state = popfirst!(now_beam)
            actions = legal_actions(now_state)
            for action in actions
                next_state = deepcopy(now_state)
                advance!(next_state, action)
                if t == 1
                    next_state.first_action = action
                end
                push!(next_beam, next_state)
            end
        end
        evaluate!.(next_beam)
        now_beam = sort(next_beam, by=state->state.evaluated_score, rev=true)
        best_state = now_beam[1]
        if is_done(best_state)
            break
        end
    end
    best_state.first_action
end

end

module AITester

using ..WallMazeGame: WallMazeState, is_done, advance!
using Distributed

function test_ai_score(ai::Pair, game_number::Int, h::Int, w::Int, end_turn::Int)
    score_mean = 0.0
    @sync @distributed for seed in 1:game_number
        state = WallMazeState(seed, h, w, end_turn)
        while !is_done(state)
            advance!(state, ai.second(state))
        end
        score_mean += state.game_score
    end
    score_mean /= game_number
    println("score mean: $(score_mean)")
end

end


# h = 7
# w = 7
# end_turn = 49
# beam_width = 100
# beam_depth = end_turn
# ai = "beam_search_agent" => state -> BeamSearchAgent.beam_search_action(state, beam_width, beam_depth)
# AITester.test_ai_score(ai, 100, h, w, end_turn)