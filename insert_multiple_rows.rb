# in practice use: gem "activerecord-import", "~> 0.2.11"
# but...
# thx to http://snipplr.com/view/1434/ for initial (albeit broken) concept 
ActiveRecord::Base.class_eval do
  def self.insert_multiple_rows( values, columns=attributes, this_table_name=table_name )
    # hmm...
    # connection.insert( multi_insert_statement( values, columns, this_table_name ) )
    connection.execute( multi_insert_statement( values, columns, this_table_name ) )
  end

  def self.multi_insert_statement( values, columns=attributes, this_table_name=table_name )
    %Q{INSERT INTO #{this_table_name} (#{columns.join(',')})
    VALUES
      #{values_statement(values)}}
  end

  def self.values_statement( values )
    values.reduce( '' ) {|m,a| m << " ('"; m << a.join("','"); m << "')"; m }
  end
end

# Now you'll be able to call, for example:

# for testing:
# class Foo < ActiveRecord::Base
#   def self.table_name
#    "tbl-name"
#   end
# end
#
# Foo.multi_insert_statement(
#  values = [["a", "b", "c"],["d", "e", "f"]],
#  columns = ["c1", "c2", "c3"],
#  this_table_name = "users"
# )
# => "INSERT INTO users (c1,c2,c3)\n    VALUES\n       ('a','b','c') ('d','e','f')" 

# Foo.values_statement([["a", "b", "c"],["d", "e", "f"]])
# => " ('a','b','c') ('d','e','f')"

# User.insert_multiple_rows(columns, values)
