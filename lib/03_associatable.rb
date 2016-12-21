require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    # ...
    class_name.constantize
  end

  def table_name
    # ...
    class_name.downcase.singularize << "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    # ...
    if options[:class_name].nil?
      self.class_name = name.to_s.capitalize
    else
      self.class_name = options[:class_name]
    end

    if options[:foreign_key].nil?
      self.foreign_key = (name.to_s << "_id").to_sym
    else
      self.foreign_key = options[:foreign_key]
    end

    if options[:primary_key].nil?
      self.primary_key = :id
    else
      self.primary_key = options[:primary_key]
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    # ...
    if options[:class_name].nil?
      self.class_name = name.to_s.singularize.capitalize
    else
      self.class_name = options[:class_name]
    end

    if options[:foreign_key].nil?
      self.foreign_key = (self_class_name.downcase << "_id").to_sym
    else
      self.foreign_key = options[:foreign_key]
    end

    if options[:primary_key].nil?
      self.primary_key = :id
    else
      self.primary_key = options[:primary_key]
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    # ...
    # options = BelongsToOptions.new(name, options)
    # define_method(name) do
    #   foreign_key = self.send(options.foreign_key)
    #   options.model_class.where(options.primary_key => foreign_key).first
    # end

    self.assoc_options[name] = BelongsToOptions.new(name, options)
    define_method(name) do
      options = self.class.assoc_options[name]
      foreign_key = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => foreign_key).first
    end
  end

  def has_many(name, options = {})
    # ...
    options = HasManyOptions.new(name, self.name, options)
    define_method(name) do
      primary_key = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => primary_key)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
