# require './lib/db'; db = DB.new; db.run_sample
require "sqlite3"
require 'forwardable'

class DB
  extend Forwardable
  attr_reader :db
  def_delegator :@db, :execute, :exec

  def initialize(db_path="test.db")
    @db = SQLite3::Database.new db_path
  end

  def run_sample
    puts "creating table..."
    create_sample_table
    num_rows = count_sample_rows
    if 0 == num_rows
      puts "adding rows..."
      insert_sample_data
    else
      puts "#{num_rows} rows already added"
    end
    puts "selecting rows:"
    select_sample_rows

    puts "dropping table..."
    drop_sample_table
  end

  private

  def drop_sample_table
    exec "drop table numbers;"
  end

  def create_sample_table
    exec <<-SQL
    create table numbers (
      name varchar(30),
      val int
    );
    SQL
    return true
  rescue Exception => e
    puts "exception: #{e.message}"
    return false
  end

  def insert_sample_data
    {
      "one" => 1,
      "two" => 2,
    }.each do |pair|
      exec "insert into numbers values ( ?, ? )", pair
    end
  end

  def count_sample_rows
    0.tap do |result|
      exec( "select count(*) from numbers" ) do |row|
        result += row.first
      end
    end
  end

  def select_sample_rows
    exec( "select * from numbers" ) do |row|
      if block_given?
        yield row
      else
        p row
      end
    end
  end
end
