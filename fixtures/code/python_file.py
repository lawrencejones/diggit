def info():
    {'indentation': '    '}


class Person(object):

    def __init__(self, name):
        self.name = name

    def say_name(self):
        print(self.name)


class Adult(Person):

    def say_name(self):
        print(self.name.upper())
