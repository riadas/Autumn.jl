module CompiledProgram
export init, next
import Base.min
using Distributions
using MLStyle: @match
using Random
using Autumn.AutumnBase
rng = Random.GLOBAL_RNG
begin
    struct Agent
        agentid::Int
        skill::Int
        altruism::Int
        wealth::Int
        workamount::Int
    end
end
begin
    struct Action
        action::String
        issue::String
        stance::Int
    end
end
begin
    struct Policy
        issue::String
        stance::Int
    end
end
begin
    struct IntrinsicState
        agents::Array{Agent}
    end
end
begin
    function createAgents(numagents)
        map((i->begin
                    Agent(i, uniformChoice(rng, [0, 1, 2]), uniformChoice(rng, [0, 1]), 0, 0)
                end), range(1, numagents))
    end
end
begin
    function nextIntrinsicState(istate, gstate, time)
        begin
            npactions = npCombinedAct(istate, gstate, time)
            iTransition(npactions, istate, gstate, time)
        end
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
        uniformChoice(rng, [Action("work", "none", -1), Action("educate", "none", -1), Action("none", "none", -1)])
    end
end
begin
    function iTransition(npactions, istate, gstate, time)
        begin
            new_agents = map((arg->begin
                            updateAgent(first(arg), last(arg))
                        end), zip(istate.agents, npactions))
            IntrinsicState(new_agents)
        end
    end
end
begin
    function updateAgent(agent, npaction)
        if npaction.action == "work"
            work(agent)
        else
            if npaction.action == "educate"
                educate(agent)
            else
                agent
            end
        end
    end
end
begin
    function work(agent)
        updateObj(updateObj(agent, "wealth", agent.wealth + 4 * (agent.skill + 1)), "workamount", agent.workamount + 1)
    end
end
begin
    function educate(agent)
        if agent.skill < 2
            updateObj(agent, "skill", agent.skill + 1)
        else
            agent
        end
    end
end
begin
    function nextGovtState(istate, gstate, time, numpanelists, issues)
        begin
            pactions = pCombinedAct(istate, gstate, time)
            gTransition(pactions, istate, gstate, time, numpanelists, issues)
        end
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
        begin
            pactionspace = getpActionSpace(istate, gstate, agent, time)
            uniformChoice(rng, pactionspace)
        end
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
        NUM_AGENTSHistory::Dict{Int64, Any}
        ISSUESHistory::Dict{Int64, Any}
    end
end
state = STATE(0, 0, Dict{Int64, Int}(), Dict{Int64, Array{Agent}}(), Dict{Int64, Array{Policy}}(), Dict{Int64, IntrinsicState}(), Dict{Int64, String}(), Dict{Int64, Any}(), Dict{Int64, Any}())
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
    function init(custom_rng = rng)::STATE
        global rng = custom_rng
        state = STATE(0, 0, Dict{Int64, Int}(), Dict{Int64, Array{Agent}}(), Dict{Int64, Array{Policy}}(), Dict{Int64, IntrinsicState}(), Dict{Int64, String}(), Dict{Int64, Any}(), Dict{Int64, Any}())
        begin
            NUM_AGENTS = 5
            ISSUES = ["apples", "bananas"]
            time = 0
            agents = createAgents(NUM_AGENTS)
            policies = [Policy("apples", 0), Policy("bananas", 0)]
            istate = IntrinsicState(agents)
            currentissue = "apples"
        end
        NUM_AGENTS = 5
        ISSUES = ["apples", "bananas"]
        state.timeHistory[state.time] = time
        state.agentsHistory[state.time] = agents
        state.policiesHistory[state.time] = policies
        state.istateHistory[state.time] = istate
        state.currentissueHistory[state.time] = currentissue
        state.NUM_AGENTSHistory[state.time] = NUM_AGENTS
        state.ISSUESHistory[state.time] = ISSUES
        global state = state
        state
    end
end
begin
    function next(old_state::STATE)::STATE
        global state = old_state
        state.time = state.time + 1
        begin
            time = state.timeHistory[state.time - 1]
            agents = state.agentsHistory[state.time - 1]
            policies = state.policiesHistory[state.time - 1]
            istate = state.istateHistory[state.time - 1]
            currentissue = state.currentissueHistory[state.time - 1]
            NUM_AGENTS = state.NUM_AGENTSHistory[state.time - 1]
            ISSUES = state.ISSUESHistory[state.time - 1]
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
        end
        state.timeHistory[state.time] = time
        state.agentsHistory[state.time] = agents
        state.policiesHistory[state.time] = policies
        state.istateHistory[state.time] = istate
        state.currentissueHistory[state.time] = currentissue
        state.NUM_AGENTSHistory[state.time] = NUM_AGENTS
        state.ISSUESHistory[state.time] = ISSUES
        global state = state
        state
    end
end
end