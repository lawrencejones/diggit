'use strict';

const info = () => { return {indentation: '  '}; };

class Person {
  constructor(name) {
    this.name = name;
  }

  sayName() {
    console.log(this.name);
  }
}

class Adult extends Person {
  sayName() {
    console.log(this.name.toUpperCase());
  }
}

module.exports = {info, Person, Adult};
