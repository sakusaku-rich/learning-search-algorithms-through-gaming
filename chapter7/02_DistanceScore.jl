include("01_GameScore.jl")

module DistanceEvaluater

using ..WallMazeGame: WallMazeState, Coord, DX, DY, legal_actions, advance!, is_done

struct DistanceCoord
    y::Int
    x::Int
    distance::Int
end

function get_distance_to_nearest_point(state::WallMazeState)::Int
    que = DistanceCoord[
        DistanceCoord(state.character.y, state.character.x, 0)
    ]
    check = falses(state.h, state.w)
    while !isempty(que)
        tmp_coord = popfirst!(que)
        if state.points[tmp_coord.y, tmp_coord.x] > 0
            return tmp_coord.distance
        end
        check[tmp_coord.y, tmp_coord.x] = true
        for action in 1:4
            ty = tmp_coord.y + DY[action]
            tx = tmp_coord.x + DX[action]
            if 1 <= ty <= state.h && 1 <= tx <= state.w && state.walls[ty, tx] == 0 && !check[ty, tx]
                push!(que, DistanceCoord(ty, tx, tmp_coord.distance + 1))
            end
        end
    end
    state.h * state.w
end

function evaluate!(state::WallMazeState, h::Int, w::Int)
    state.evaluated_score = state.game_score * h * w - get_distance_to_nearest_point(state)
end

end


module BeamSearchWithDistanceScoreAgent
using ..WallMazeGame: WallMazeState, Coord, DX, DY, legal_actions, advance!, is_done
using ..DistanceEvaluater: evaluate!

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
        evaluate!.(next_beam, state.h, state.w)
        now_beam = sort(next_beam, by=state->state.evaluated_score, rev=true)
        best_state = now_beam[1]
        if is_done(best_state)
            break
        end
    end
    best_state.first_action
end

end

# h = 7
# w = 7
# end_turn = 49
# beam_width = 100
# beam_depth = end_turn
# ai = "beam_search_agent" => state -> BeamSearchWithDistanceScoreAgent.beam_search_action(state, beam_width, beam_depth)
# AITester.test_ai_score(ai, 100, h, w, end_turn)