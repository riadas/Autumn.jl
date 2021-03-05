# Autumn Program Writing Tutorial

### Autumn Language

Some important built-in types:

- Position: arguments are *x* and *y* integer coordinates (e.g. (Position 0 0), (Position 1 1), etc.)
- Cell: arguments are *position* of type Position and *color* of type String (only certain string colors will actually work), but multiple Cell constructors exist, so that the following are both valid constructions of a Cell type:
    - (Cell (Position 0 0) "blue")
    - (Cell 0 0 "blue") ← this constructor takes the deconstructed *x* and *y* coordinates as input rather than a Position type
    - Note: An opacity argument also exists, but isn't currently handled by the interface — this should be fixed (default opacity for all colors/cells is 0.8).
    - Note: Cells correspond to the squares of the grid (each has a position and a color)

### Deconstructing an Autumn Program

Sample Program: particles.sx

```lisp
(program
  (= GRID_SIZE 16)
  
  (object Particle (Cell 0 0 "blue"))

  (: particles (List Particle))
  (= particles 
     (initnext (list) (updateObj (prev particles) (--> obj (Particle (uniformChoice (adjPositions (.. obj origin))))))))	
  
  (on clicked (= particles (addObj (prev particles) (Particle (Position (.. click x) (.. click y))))))
)
```

Every Autumn program can be divided into four parts:

1. Object Type Definitions
2. Object Instance Definitions
3. Events (On Clauses)
4. Non-Object Variable Definitions/Constants

**1. Object Type Definitions**:

```lisp
/* ... */
(object Particle (Cell 0 0 "blue"))
/* ... */
```

Autumn models are all defined in terms of *objects*, which have the following definition syntax:

`(object [objectName] [0 or more*custom field* definitions] [render])`.

In the particles example, the Particle object has no custom fields.

Autumn object definitions compile down to structs in Julia with a few default fields:

- id: used to internally track objects (i.e. within Julia)
- origin: specifies where on the grid the object should be rendered
- alive: specifies whether the Autumn rendering function should render this object
- render: specifies the shape of the object, as a list of **Cell** structs relative to the origin position (0, 0)

as well as some potentially custom fields (will be explained shortly). Only the *origin*, *alive*, and *render* fields are exposed to the user, while the *id* field is only used internally. (Technically, the current working implementation allows a user to access the id, but this will be fixed.) In addition to the object struct, the compiler also generates a constructor for the object type with the same name as the object, that takes as arguments any custom field values and the origin value. In the particles example, this constructor (in Julia) has the following signature:

`function Particle(origin::Position)`. 

The type of the *render* property is a list of cells, but unicellular objects like Particle can also be specified without the list syntax, i.e.

`(object Particle (list (Cell 0 0 "blue")))` and

`(object Particle (Cell 0 0 "blue"))` 

are equivalent (the compiler turns the latter into the former).

**Custom fields**:

Custom fields can be specified as follows:

`(object ModifiedParticle (: [fieldName1] [fieldType1] ) (: [fieldName2] [fieldType2] ) (Cell 0 0 "blue"))`,

i.e. with type declarations of the custom fields between the object type name and the render value. Some concrete examples are below:

`(object Light (: on Bool) (Cell 0 0 (if on then "yellow" else "black")))`

`(object Snake (: head Cell) (: tail (List Cell)) (: direction Position) (list head tail))`

`(object Magnet (: isAttached Bool) (list (Cell 0 0 "red") (Cell 0 1 "blue")))`

Note that the custom fields can be used as part of the render value, and that if the render value is a nested list of cells (e.g. `(list head tail)`), then it is automatically flattened by the compiler, so it behaves as usual.

**2. Object Instance Definitions**:

```lisp
/* ... */
(: particles (List Particle))
(= particles 
   (initnext (list) (updateObj (prev particles) (--> obj (Particle (uniformChoice (adjPositions (.. obj origin))))))))	
/* ... */
```

Objects can be introduced into the scene in two forms: (1) as part of a list of objects and (2) as a single, self-contained object variable. To introduce an object, you must declare its type, and use `initnext` to define its initial value and subsequent behavior on clock ticks. No other code (e.g. an add to scene call) is necessary; Autumn treats all objects defined in the program as inherently in the scene.

A list of objects definition is in particles.sx. An example of a non-list object instance definition (i.e. different from the particles example) is below:

```lisp
(: particle Particle)
(= particle (initnext (Particle (Position 5 5)) (prev particle)))
```

Importantly, without an object type declaration, the compiler will not recognize an object variable as an object, so it will be handled incorrectly. In other words, writing just the second line above will not work properly.

**3. Events (On Clauses)**:

```lisp
/* ... */
(on clicked (= particles (addObj (prev particles) (Particle (Position (.. click x) (.. click y))))))
```

The form of an event is

`(on [boolean clause] [update assignment(s)])`.

There are a few useful keywords that serve as shorthands for boolean clauses in the on context:

- `clicked` ← indicates that the grid was clicked (at any position)
- `left`/ `right` / `up` / `down` ← indicates whether respective arrow key was pressed

In addition, the following boolean functions (signatures given in Julia) are also common:

- `clicked(position::Position)` - clicked a particular position
- `clicked(obj::Object)` - clicked a particular object
- `clicked(objs::Array{Object})` - clicked at least one object out of a list of objects

Note also that `(.. click x)` and `(.. click y)` can be used to access a click's coordinates in an update assignment that follows a boolean clause related to clicked.

The update assignment is either a re-assignment of the value of an existing object variable, or a series of such re-assignments, wrapped in a let clause. Some examples are below:

- `(= particles (addObj (prev particles) (Particle (Position (.. click x) (.. click y)))))`
- `(on (clicked clearButton) (let ((= vessels (list)) (= plugs (list)) (= water (list)))))` (from Water Plug in logic.toys)

**4. Non-Object Variable Definitions/Constants**:

```lisp
(= GRID_SIZE 16)
/* ... */
```

All Autumn programs must specify an integer `GRID_SIZE`, and can also specify an optional background color (`background` must currently be a String constant, but can be extended to support varying values). Other non-object variables (e.g. relating to the state of the program) may also be defined, though the particles example doesn't have any of these state variables.

### Some Useful Library Functions

- `updateObj(obj::Object, field::String, value)`
- `updateObj(objs::Array{Object}, updatefunc)`
- `addObj(objs::Array{Object}, obj::Object)`
- `removeObj(objs::Array{Object}, filterfunc)`
- `removeObj(objs::Array{Object}, obj::Object)`
- `removeObj(obj::Object)` - this sets the object's alive property to false (using the first updateObj function can reset it to true, if desired)

### Library Reference

[https://github.com/riadas/autumnal/blob/master/app/resources/autumnmodels/AutumnModelsController.jl#L651](https://github.com/riadas/autumnal/blob/master/app/resources/autumnmodels/AutumnModelsController.jl#L651)