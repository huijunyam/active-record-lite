require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    return @column if @column

    title = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @column = title.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method("#{col}") do
        self.attributes[col]
      end

      define_method("#{col}=") do |val|
        self.attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    capital_letter = self.to_s.scan(/[A-Z]/)
    self.to_s.chars.map.with_index do |char, idx|
      if capital_letter.include?(char) && idx != 0
        "_#{char}"
      else
        char
      end
    end.join("").downcase << "s"
  end

  def self.all
    # ...
    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(result)
  end

  def self.parse_all(results)
    # ...
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    # ...
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    parse_all(result).first
  end

  def initialize(params = {})
    # ...
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    # ...
    @attributes ? @attributes : @attributes = {}
  end

  def attribute_values
    # ...
    self.class.columns.map { |attr| self.send("#{attr}") }
  end

  def insert
    # ...
    col_names = self.class.columns.drop(1).map(&:to_s).join(",")
    question_marks = (["?"] * attribute_values.drop(1).length).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    set_line = self.class.columns.drop(1).map { |attr_name| "#{attr_name} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, attribute_values.drop(1), attribute_values.first)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    # ...
    self.id.nil? ? insert : update
  end
end
