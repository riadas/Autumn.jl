# Autumn Language

## Types

Autumn has support for structure, which are product types with concretely typed fields.  For example:

```elm
struct MyType x::Int y::Bool
```

## Objects

An `Object` is a special type containing (i) custom fields, (ii) an integer identity

```elm
Object MyObject somefield::Int someotherField::Bool cells::Cells
```

To create a noew object

```elm
objectName = MyObject 2 3 somePosition
```

## Init-next
Time-varying values can be specified using `init-next`

```elm
x = init someInitialValue
    next someNextValue
```

## On-clauses

On-clauses define interventions to the normal dynamics

```
on somePredicate
  x = someValue
```