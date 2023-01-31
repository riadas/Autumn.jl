var parse = require('s-expression');

// Construct Autumn Expression (AExpr) from program string
export function parseau(program_str) {
  sexpr = parse(program_str);
  aexpr = s_to_a(sexpr); 
  return aexpr;
}

// Convert S-Expression (SExpr) to Autumn Expression (AExpr)
function s_to_a(sexpr) {
  if (Array.isArray(sexpr)) { 
    if (sexpr[0] == "program") {
      return {"head" : "", "args" : sexpr.slice(1).map(line => s_to_a(line))};
    } else if (sexpr[0] == "if") {
      return {"head" : "if", "args" : [s_to_a(sexpr[1]), s_to_a(sexpr[3]), s_to_a(sexpr[5])]};
    } else if (sexpr[0] == "initnext") {
      return {"head" : "initnext", "args" : [s_to_a(sexpr[1]), s_to_a(sexpr[2])]};
    } else if (sexpr[0] == "=") {
      return {"head" : "assign", "args" : [sexpr[1], s_to_a(sexpr[2])]};
    } else if (sexpr[0] == ":") {
      return {"head" : "typedecl", "args" : [sexpr[1], s_to_a(sexpr[2])]};
    } else if (sexpr[0] == "let") {
      return {"head" : "let", "args" : sexpr[1].map(line => s_to_a(line))};
    } else if (sexpr[0] == "fn") {
      return {"head" : "fn", "args" : [{"head" : "list", "args" : sexpr[1]}, s_to_a(sexpr[2])]};
    } else if (sexpr[0] == "-->") {
      return {"head" : "lambda", "args" : [s_to_a(sexpr[1]), s_to_a(sexpr[2])]};
    } else if (sexpr[0] == "..") {
      return {"head" : "field", "args" : [s_to_a(sexpr[1]), s_to_a(sexpr[2])]};
    } else if (sexpr[0] == "on") {
      return {"head" : "on", "args" : [s_to_a(sexpr[1]), s_to_a(sexpr[2])]};
    } else if (sexpr[0] == "object") {
      return {"head" : "object", "args" : [s_to_a(sexpr[1]), s_to_a(sexpr[2])]};
    } else if (sexpr.length > 1) {
      return {"head" : "call", "args" : [s_to_a(sexpr[0]), sexpr.slice(1).map(s => s_to_a(s))]};
    } else {
      return {"head" : "list", "args" : sexpr.map(elt => s_to_a(elt))};
    } 
  } else if (!isNaN(sexpr)) {
    return parseInt(sexpr);
  } else if (typeof(sexpr) == "string") {
    return sexpr;
  } else {
    return {"str" : sexpr.valueOf()};
  }
}