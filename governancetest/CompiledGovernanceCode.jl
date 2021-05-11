module CompiledProgram
export init, next
import Base.min
using Distributions
using MLStyle: @match
using Random
using Autumn.AutumnBase
rng = Random.GLOBAL_RNG
begin
    mutable struct Agent <: Object
        id::Int
        origin::Position
        alive::Bool
        hidden::Bool
        id::Int
        wealth::Int
        skill::Int
        workamount::Int
        render::Array{Cell}
    end
    function Agent(id::Int, wealth::Int, skill::Int, workamount::Int, origin::Position)::Agent
        state.objectsCreated += 1
        rendering = Cell(0, 0, "black")
        Agent(state.objectsCreated, origin, true, false, id, wealth, skill, workamount, if rendering isa AbstractArray
                vcat(rendering...)
            else
                [rendering]
            end)
    end
end
begin
    mutable struct Action <: Object
        id::Int
        origin::Position
        alive::Bool
        hidden::Bool
        action::String
        issue::String
        stance::Int
        render::Array{Cell}
    end
    function Action(action::String, issue::String, stance::Int, origin::Position)::Action
        state.objectsCreated += 1
        rendering = Cell(0, 0, "black")
        Action(state.objectsCreated, origin, true, false, action, issue, stance, if rendering isa AbstractArray
                vcat(rendering...)
            else
                [rendering]
            end)
    end
end
begin
    mutable struct Policy <: Object
        id::Int
        origin::Position
        alive::Bool
        hidden::Bool
        issue::String
        stance::Int
        render::Array{Cell}
    end
    function Policy(issue::String, stance::Int, origin::Position)::Policy
        state.objectsCreated += 1
        rendering = Cell(0, 0, "black")
        Policy(state.objectsCreated, origin, true, false, issue, stance, if rendering isa AbstractArray
                vcat(rendering...)
            else
                [rendering]
            end)
    end
end
begin
    mutable struct IntrinsicState <: Object
        id::Int
        origin::Position
        alive::Bool
        hidden::Bool
        agents::Array{Agent}
        render::Array{Cell}
    end
    function IntrinsicState(agents::Array{Agent}, origin::Position)::IntrinsicState
        state.objectsCreated += 1
        rendering = Cell(0, 0, "black")
        IntrinsicState(state.objectsCreated, origin, true, false, agents, if rendering isa AbstractArray
                vcat(rendering...)
            else
                [rendering]
            end)
    end
end
begin
    function createAgents(numAgents)
        map((i->begin
                    Agent(i, Position(0, 0))
                end), range(1, NUM_AGENTS))
    end
end
begin
    function nextIntrinsicState(istate, gstate, time)
        let($(Expr(:(=), :npactions, :(npCombinedAct(istate, gstate, time)))), iTransition(npactions, istate, gstate, time))
    end
end
begin
    function npCombinedAct(istate, gstate, time)
        map((agent->begin
                    npAct(agent, istate, gstate, time)
                end), istate.agents)
    end
end
begin
    function npAct(agent, istate, gstate, time)
        uniformChoice(rng, [Action("work", "none", -1, Position(0, 0)), Action("educate", "none", -1, Position(0, 0)), Action("none", "none", -1, Position(0, 0))])
    end
end
begin
    function iTransition(npactions, istate, gstate, time)
        begin
            new_agents = foreach((arg->begin
                            updateAgent(first(arg), last(arg))
                        end), zip(agents, npactions))
            IntrinsicState(new_agents, Position(0, 0))
        end
    end
end
begin
    function updateAgent(agent, npaction)
        if npaction.action = "work"
            work(agent)
        else
            if npaction.action = "educate"
                educate(agent)
            else
                agent
            end
        end
    end
end
begin
    function nextGovtState(istate, gstate, time)
        let($(Expr(:(=), :pactions, :(pCombinedAct(istate, gstate, time)))), gTransition(pactions, istate, gstate, time))
    end
end
begin
    function pCombinedAct(istate, gstate, time)
        map((agent->begin
                    pAct(agent, istate, gstate, time)
                end), istate.agents)
    end
end
begin
    function pAct(agent, istate, gstate, time)
        let($(Expr(:(=), :pactionspace, :(getpActionSpace(istate, gstate, agent, time)))), uniformChoice(rng, pactionspace))
    end
end
begin
    mutable struct STATE
        time::Int
        objectsCreated::Int
        timeHistory::Dict{Int64, Int}
        agentsHistory::Dict{Int64, Array{Agent}}
        policiesHistory::Dict{Int64, Array{Policy}}
        istateHistory::Dict{Int64, IntrinsicState}
        currentissueHistory::Dict{Int64, String}
        GRID_SIZEHistory::Dict{Int64, Int}
        NUM_AGENTSHistory::Dict{Int64, Any}
        ISSUESHistory::Dict{Int64, Any}
        backgroundHistory::Dict{Int64, String}
    end
end
state = STATE(0, 0, Dict{Int64, Int}(), Dict{Int64, Array{Agent}}(), Dict{Int64, Array{Policy}}(), Dict{Int64, IntrinsicState}(), Dict{Int64, String}(), Dict{Int64, Int}(), Dict{Int64, Any}(), Dict{Int64, Any}(), Dict{Int64, String}())
begin
    function timePrev(n::Int = 1)::Int
        state.timeHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function agentsPrev(n::Int = 1)::Array{Agent}
        state.agentsHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function policiesPrev(n::Int = 1)::Array{Policy}
        state.policiesHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function istatePrev(n::Int = 1)::IntrinsicState
        state.istateHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function currentissuePrev(n::Int = 1)::String
        state.currentissueHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function GRID_SIZEPrev(n::Int = 1)::Int
        state.GRID_SIZEHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function NUM_AGENTSPrev(n::Int = 1)::Any
        state.NUM_AGENTSHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function ISSUESPrev(n::Int = 1)::Any
        state.ISSUESHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function backgroundPrev(n::Int = 1)::String
        state.backgroundHistory[if state.time - n >= 0
                state.time - n
            else
                0
            end]
    end
end
begin
    function init(custom_rng = rng)::STATE
        global rng = custom_rng
        state = STATE(0, 0, Dict{Int64, Int}(), Dict{Int64, Array{Agent}}(), Dict{Int64, Array{Policy}}(), Dict{Int64, IntrinsicState}(), Dict{Int64, String}(), Dict{Int64, Int}(), Dict{Int64, Any}(), Dict{Int64, Any}(), Dict{Int64, String}())
        begin
            GRID_SIZE = 10
            NUM_AGENTS = 5
            ISSUES = ["apples", "bananas"]
            background = "white"
            time = 0
            agents = createAgents(NUM_AGENTS)
            policies = [Policy("apples", 0, Position(0, 0)), Policy("bananas", 0, Position(0, 0))]
            istate = IntrinsicState(agents, Position(0, 0))
            currentissue = "apples"
        end
        NUM_AGENTS = 5
        ISSUES = ["apples", "bananas"]
        background = "white"
        state.timeHistory[state.time] = time
        state.agentsHistory[state.time] = agents
        state.policiesHistory[state.time] = policies
        state.istateHistory[state.time] = istate
        state.currentissueHistory[state.time] = currentissue
        state.GRID_SIZEHistory[state.time] = GRID_SIZE
        state.NUM_AGENTSHistory[state.time] = NUM_AGENTS
        state.ISSUESHistory[state.time] = ISSUES
        state.backgroundHistory[state.time] = background
        global state = state
        state
    end
end
begin
    function next(old_state::STATE)::STATE
        global state = old_state
        state.time = state.time + 1
        GRID_SIZE = 10
        begin
            time = state.timeHistory[state.time - 1]
            agents = state.agentsHistory[state.time - 1]
            policies = state.policiesHistory[state.time - 1]
            istate = state.istateHistory[state.time - 1]
            currentissue = state.currentissueHistory[state.time - 1]
            GRID_SIZE = state.GRID_SIZEHistory[state.time - 1]
            NUM_AGENTS = state.NUM_AGENTSHistory[state.time - 1]
            ISSUES = state.ISSUESHistory[state.time - 1]
            background = state.backgroundHistory[state.time - 1]
            begin
                if !(foldl(|, []; init = false))
                    time = timePrev() + 1
                    agents = agentsPrev()
                    policies = policiesPrev()
                    istate = nextIntrinsicState(istatePrev(), gstatePrev(), timePrev())
                    currentissue = currentissuePrev()
                end
            end
            NUM_AGENTS = 5
            ISSUES = ["apples", "bananas"]
            background = "white"
        end
        state.timeHistory[state.time] = time
        state.agentsHistory[state.time] = agents
        state.policiesHistory[state.time] = policies
        state.istateHistory[state.time] = istate
        state.currentissueHistory[state.time] = currentissue
        state.GRID_SIZEHistory[state.time] = GRID_SIZE
        state.NUM_AGENTSHistory[state.time] = NUM_AGENTS
        state.ISSUESHistory[state.time] = ISSUES
        state.backgroundHistory[state.time] = background
        global state = state
        state
    end
end
end