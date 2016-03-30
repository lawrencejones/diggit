import PEG from 'pegjs';
import grammar from './grammar.pegjs!text'

/* Must be able to parse expressions like...
 *
 * \forall x (Foo(x) -> \exists y Bar(x, y))
 *
 */
export const Parser = PEG.buildParser(grammar);
