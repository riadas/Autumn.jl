(program
    (= GRID_SIZE 10)
    (= NUM_AGENTS 5)
    (= NUM_PANELISTS 3)
    (= ISSUES (list "apples" "bananas"))
    (= background "white")

    ; object definitions
    (object Agent (: agentid Int) (: wealth Int) (: skill Int) (: workamount Int) (Cell 0 0 "black"))
    ; action can be "work", "educate", "vote", or "none" -- issue and stance are unused unless action is "vote"
    (object Action (: action String) (: issue String) (: stance Int) (Cell 0 0 "black"))
    (object Policy (: issue String) (: stance Int) (Cell 0 0 "black"))
    (object IntrinsicState (: agents (List Agent)) (Cell 0 0 "black"))
    (object SortitionState (: panel (List Int)) (: currentissue String) (: policies (List Policy)) (Cell 0 0 "black"))

    ; instantiations
    (: time Int)
    (= time (initnext 0 (+ (prev time) 1)))
    (: agents (List Agent))
    (= agents (initnext
        (createAgents NUM_AGENTS)
        (prev agents)))
    (: policies (List Policy))
    (= policies (initnext
        (list (Policy "apples" 0 (Position 0 0)) (Policy "bananas" 0 (Position 0 0)))
        (prev policies)
    ))
    (: istate IntrinsicState)
    (= istate (initnext
        (IntrinsicState agents (Position 0 0))
        (nextIntrinsicState (prev istate) (prev gstate) (prev time))))
    
    ; sortition-specific instantiations
    (: panel (List Int))
    (= panel (list 1 2 3))
    (: currentissue String)
    (= currentissue (initnext "apples" (prev currentissue)))
    (: gstate SortitionState)
    (= gstate (initnext
        (SortitionState panel currentissue policies (Position 0 0))
        (nextGovtState (prev istate) (prev gstate) (prev time))))
    
    ; functions
    (= createAgents (fn (numAgents) (
        map (--> i (Agent i (Position 0 0))) (range 1 NUM_AGENTS)
    )))

    (= nextIntrinsicState (fn (istate gstate time) (
        let (= npactions (npCombinedAct istate gstate time))
        (iTransition npactions istate gstate time)
    )))

    (= npCombinedAct (fn (istate gstate time) (
        map (--> agent (npAct agent istate gstate time)) (.. istate agents)
    )))

    (= npAct (fn (agent istate gstate time) (
        uniformChoice (list
        (Action "work" "none" -1 (Position 0 0))
        (Action "educate" "none" -1 (Position 0 0))
        (Action "none" "none" -1 (Position 0 0)))
    )))

    (= iTransition (fn (npactions istate gstate time) (
        ; npactions is assumed to be a list of npactions, in the same order as list of agents
        let ((= new_agents (foreach (--> arg (updateAgent (first arg) (last arg))) (zip agents npactions)))
        ; return new istate
        (IntrinsicState new_agents (Position 0 0))
    ))))

    (= updateAgent (fn (agent npaction) (
        if (= (.. npaction action) "work")
        then (work agent)
        else (if (= (.. npaction action) "educate")
              then (educate agent)
              else agent)
    )))

    (= nextGovtState (fn (istate gstate time) (
        let (= pactions (pCombinedAct istate gstate time))
        (gTransition pactions istate gstate time)
    )))

    (= pCombinedAct (fn (istate gstate time) (
        map (--> agent (pAct agent istate gstate time)) (.. istate agents)
    )))

    (= pAct (fn (agent istate gstate time) (
        let (= pactionspace (getpActionSpace istate gstate agent time))
        (uniformChoice pactionspace)
    )))

    ; sortition-specific
    (= getpActionSpace (fn (istate gstate agent time) (
        if (== (% time 2) 0)
        then (list (Action "none" "none" -1 (Position 0 0)))  ; panel gets randomly selected, agents take no paction
        else (
            if (in (.. agent agentid) (.. gstate panel))
            then (list (Action "vote" (.. gstate currentissue) 0 (Position 0 0)) (Action "vote" (.. gstate currentissue) 1 (Position 0 0)))
            else (list (Action "none" "none" -1 (Position 0 0)))  ; non-panel members can't do anything
        )
    )))

    (= gTransition (fn (pactions istate gstate time) (
        if (== (% time 2) 0)
        then (
            let
            (= newpanel (map (--> obj (.. obj agentid)) (uniformChoice (.. istate agents) NUM_PANELISTS)))
            (= newissue (uniformChoice ISSUES))
            ; return new gstate
            (updateObj (updateObj gstate "issue" newissue) "panel" newpanel)  ; nested call
        )
        else (
            let
            (= forvotes (length (filter (--> obj (&& (== (.. obj action) "vote") (== (.. obj stance) 1))) pactions)))
            (= majoritystance (if (> forvotes (/ NUM_PANELISTS 2)) then 1 else 0))
            (= newpolicies (updateObj (.. gstate policies) (--> obj (if (== (.. obj issue) (.. gstate currentissue)) then (updateObj obj "stance" majoritystance) else obj))))
            ; return new gstate
            (updateObj gstate "policies" newpolicies)
        )
    )))
)