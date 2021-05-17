module CompiledProgram
export init, next
import Base.min
using Distributions
using Random
using Autumn.AutumnBase
rng = Random.GLOBAL_RNG
begin
    struct Click
    end
end
begin
    struct Thing
        x::Int
        y::Bool
    end
end
begin
    mutable struct STATE
        time::Int
        objectsCreated::Int
        thingHistory::Dict{Int64, Thing}
        std_testHistory::Dict{Int64, Array{Int}}
        randintHistory::Dict{Int64, Int}
        arangeHistory::Dict{Int64, Array{Int}}
        clickHistory::Dict{Int64, Union{Click, Nothing}}
    end
end
state = STATE(0, 0, Dict{Int64, Thing}(), Dict{Int64, Array{Int}}(), Dict{Int64, Int}(), Dict{Int64, Array{Int}}(), Dict{Int64, Union{Click, Nothing}}())
begin
    function thingPrev(n::Int = 1)::Thing
        state.thingHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function std_testPrev(n::Int = 1)::Array{Int}
        state.std_testHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function randintPrev(n::Int = 1)::Int
        state.randintHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function arangePrev(n::Int = 1)::Array{Int}
        state.arangeHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function clickPrev(n::Int = 1)::Union{Click, Nothing}
        state.clickHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function init(click::Union{Click, Nothing}, custom_rng = rng)::STATE
        global rng = custom_rng
        state = STATE(0, 0, Dict{Int64, Thing}(), Dict{Int64, Array{Int}}(), Dict{Int64, Int}(), Dict{Int64, Array{Int}}(), Dict{Int64, Union{Click, Nothing}}())
        begin
            arange = range(1, 5)
            thing = Thing(0, 1 == 2)
            std_test = [0, 1]
            randint = 0
        end
        arange = range(1, 5)
        state.clickHistory[state.time] = click
        state.thingHistory[state.time] = thing
        state.std_testHistory[state.time] = std_test
        state.randintHistory[state.time] = randint
        state.arangeHistory[state.time] = arange
        global state = state
        state
    end
end
begin
    function next(old_state::STATE, click::Union{Click, Nothing})::STATE
        global state = old_state
        state.time = state.time + 1
        begin
            thing = state.thingHistory[state.time - 1]
            std_test = state.std_testHistory[state.time - 1]
            randint = state.randintHistory[state.time - 1]
            arange = state.arangeHistory[state.time - 1]
            begin
                if !(foldl(|, []; init = false))
                    thing = Thing(1 - (thingPrev()).x, !((thingPrev()).y))
                    std_test = push!(std_test, 2)
                    randint = uniformChoice(rng, std_test)
                end
            end
            arange = range(1, 5)
        end
        state.clickHistory[state.time] = click
        state.thingHistory[state.time] = thing
        state.std_testHistory[state.time] = std_test
        state.randintHistory[state.time] = randint
        state.arangeHistory[state.time] = arange
        global state = state
        state
    end
end
end