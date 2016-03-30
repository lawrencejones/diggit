Formula = Expression

Expression = e:Quantifier / e:Predicate / '(' _* e:Expression _* ')'{ return e }

Quantifier = '\\' quantifier:QuantifierLabel _ operand:FreeVar _ expr:Expression{
    return { type: 'quantifier', quantifier: quantifier, operand: operand, expr: expr };
  }

Predicate
  = name:PredicateName '(' operand:FreeVar ')'{
    return { type: 'predicate', predicate: name, operand: operand };
  }

QuantifierLabel = 'forall' / 'exists'
PredicateName = h:[A-Z]t:[a-z]*{ return h + t.join('') }
FreeVar = [a-z]
_ = [ \t\r\n]
