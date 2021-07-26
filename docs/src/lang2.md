# Autumn Language 2

Autumn is a programming language for modeling phenomena which exhibit more or more of the following properties:

- Dynamics — varies as a function of time
- Reactivity — varies in response to external changes
- Statefulness — retains state / memory
- Structure — has continuous and discrete data structures
- Non-determinism — state evolves probabilistically

### Standard Features

Autumn is a functional language; many of its constructs are standard. `x = val`  defines the symbol `x` to be the value `val`. The expression `let x = var in expr` defines the value `x` for use in another expression.   `f arg1 arg2 ... = expr` defines a function `f` with arguments and body `expr`.

```elm
-- Bind the name `x` to the value `3`
x = 3

-- Define a function with name `f` which increments its input
f x = x + 1

-- Apply f to x to yield value, bind to name `y`
y = f x

z = let
    -- Defines local variable `a = f(x)`
    a = f x
  in
    -- Apply anonymous function to value `a`
    (\v -> v * 2) a
```

### Types and Traits

Autumn has four concepts: values, types, traits, and representations.

A value is.  For instance, the symbol `1` is a value.  Functions can be defined directly on values, without the use of any variables at all.

```elm
-- lastname is a function which maps the input zenna to the output tavares
lastname :zenna = tavares
lastname :ria = das
```

**Type**

A type is a set of values

```elm
-- Bool is the either True or False
Bool = True | False
Bool = {True, False}

-- We can represent an Integer as the set of numbers 0 to 9
Int = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

1 + 1 = 2

```

**Representation**

Often we can use one kind of thing to represent many other kinds of thing.

```elm
-- Height can be represented as an Integer
Height as Int

-- Distance can also be represented as an Integer
Distance as Int

-- We can use a pair of numbers to represent a Point
Point as x:Int y:Int

-- We can represent a Ray as having an origin and a direction 
Ray as orig:Point dir:Point

-- Functions
p:Point = p.x + p.y
```

**Traits**

A trait is a property that values can have.  Values can have traits.

```elm
-- Jack has the property of being Doable
Jack is Doable

-- So does Jill
Jill is Doable
```

The purpose of a trait is that you can add behaviours on 

```elm
f x:Doable y:Doable = x + y
```

We can add traits to more than one value at a time by adding traits to a type

```elm
Family = Jack | Jill

-- ∀ x in Family, Doable x 
Family is Doable
```

Functions can be defined with respect to traits

```elm
-- Lists are Iterable
List is Indexable

f x:Indexable = x[1]
```

### External Variables

Autumn supports external variables.  The values of external variables are not defined within the program itself but come externally as inputs from the outside.   External variables can be used to capture user inputs, or random inputs.

```elm
-- A position is represented as an Int
Pos as x:Pos y:Pos

-- A click is represented as a Position
Click as Pos

-- An external input
external click : Click
```

### Events

System dynamics are modeled using the `on` construct `on event change` .  For example, in the following program, the value of `x` is `0` until the mouse is clicked, at which point it becomes 3:

```elm
x = 0
on click
   x => 3
```

More generally, `on` usage follows the structure:

```elm
on some_event_occured
   some_change_occurs
```

Any Boolean value is permissible as an event as the first argument of `on`.  ***[Is it just a Boolean value or a change in a Boolean value?].***  These may be primitive external events, such as mouse clicking, as well as events that are computed internally within the model.

```elm
x : Int
x = 0

-- On click, x is incremented
on click
  x => x + 1

-- When x becomes 10, it is reset to 0
on x == 10
  x = 0

x2 = {x | y = 3}

```

The second argument to `on` is some change that occurs in response to an event occurring.  ***[What kind of thing is this formally? seems like an intervention]***

Autumn allows you to refer to previous values of a variable using the construct `prev`.  For example, in the following program, `x` is initialized at `0`, then increases at each tick ***[can we make x increment without tick?]***

```elm
x = 0
on tick
  x => (prev x) + 1
```

### Quantification

It's often useful to be able to describe events that occur.

Autumn includes a universal quantifier `forall.`

```elm
forall x in someTrait
  on changed x
     x => prev x
```

We can describe events that 

```elm
forall x in =

```

### Probability

Autumn programs may be probabilistic.  Autumn programs use the `~` to draw samples from random variables.

```elm
x = ~ uniformChoice 0 1
```

Probabilistic Autumn programs are actually simply functions from an external random input $\omega$ that is automatically included.

```elm
external ω : Ω
--
x = (uniformChoice 0 1) ω
```

### Objects

Autumn programs often contain objects.  Objects have a physical location and potentially latent state.  These may be models of physical objects.

```elm
Object Ant
```

Different objects have different int

```elm
x = (Ant Position 1, 1) (Ant Position 1 1)
```

### Agents
