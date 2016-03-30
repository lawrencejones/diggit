def info
  { indentation: '  ' }
end

class Person
  def initialize(name)
    @name = name
  end

  def say_name
    puts(@name)
  end
end

class Adult < Person
  def say_name
    puts(@name.upcase)
  end
end
