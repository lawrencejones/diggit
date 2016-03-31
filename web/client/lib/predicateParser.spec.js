import {Parser} from './predicateParser.js';

describe('predicateParser', () => {
  describe('.parse', () => {
    const parse = Parser.parse.bind(Parser);

    describe('forall quantifier with nested expression', () => {
      const input = `\\forall x (Foo(x))`;

      it('identifies forall', () => {
        expect(parse(input).quantifier).toEqual('forall');
      });

      it('parses operand', () => {
        expect(parse(input).operand).toEqual('x');
      });

      it('parses inner expression', () => {
        let expr = parse(input).expr;

        expect(expr).toEqual(jasmine.objectContaining({
          type: 'predicate',
          predicate: 'Foo',
          operand: 'x',
        }));
      });
    });
  });
});
