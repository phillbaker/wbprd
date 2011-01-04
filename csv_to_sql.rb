require 'rubygems'
require 'fastercsv'
require 'sqlite3'
require 'test/unit'

module LuminWestBengalSms
  class<<self
    def setup_table db
      unless table_exists?(db, table_name())
        db.execute_batch(table_defn())
      end
    end

    def table_exists? db, name
      #sqlite specific...
      db.get_first_value("SELECT name FROM sqlite_master WHERE name='" + name + "'")
    end

    def create_db db_name
      SQLite3::Database.new("#{db_name}.sqlite")
    end

    def table_name
      'wb_water_sms'
    end

    def table_defn
      "CREATE TABLE #{table_name()} (
        id integer primary key autoincrement, 
        date date,
        district text,
        block text,
        panchayat text,
        mouza text,
        type text,
        source text,
        hamlet text,
        lab text,
        code text,
        arsenic NUMERIC,
        tds NUMERIC,
        salinity NUMERIC,
        fluoride NUMERIC,
        iron NUMERIC,
        tc NUMERIC,
        fc NUMERIC,
        ph NUMERIC,
        hardness NUMERIC
      )"
    end

    def process_csv file
      arr = FasterCSV.read(file)
      headers = arr[0]
      arr = arr[1..-1] #take off the headers
    
      #parse the date strings into ruby dates
      arr.each do |o|
        d = o[0].split('/')
        o[0] = Date.civil(d.last.to_i, d[1].to_i, d.first.to_i).to_s
      end
      
      #turn any empty values in all of the arrays into NULL values
      
      return headers, arr
    end

    def write_table db, columns, data
      data.each do |o|
        begin
          write_row(db, columns, o)
        rescue SQLite3::SQLException => e
          p o
          exit(1)
        end
      end
    end
  
    #Date,District,Block,Panchayat,Mouza,Type,Source,Hamlet,Lab,Code,Arsenic,TDS,Salinity,Fluoride,Iron,TC,FC,PH,Hardness
    def write_row db, columns, data
      column_sql = columns.join(', ')
      #brk = false
      #wrap string data types in single quotes, otherwise let it be (ie Numeric should stay numeric)
      data_quoted = data.collect do |o|
        ret = o
        if o.is_a?(String)
          o = SQLite3::Database.quote(o) #need to escape single quotes, not c-style for sqlite, but two single quotes
          ret = "'#{o}'"
        elsif o == nil
          ret = 'NULL'
          #brk = true
        end
        ret
      end
      data_sql = data_quoted.join(', ')
      sql = %{INSERT INTO %s ( %s ) VALUES ( %s ) } % [table_name(), column_sql, data_sql]
      #puts sql
      #exit(0)
      statement = db.prepare(sql)
      statement.execute!
    end
  end
  
  class LuminWestBengalSmsTest #< Test::Unit::TestCase
    include LuminWestBengalSms
    
    def setup
      @db = SQLite3::Database.new(":memory:")
    end

    #def test_process_csv
    #end

    def test_table_defn
      assert_nothing_raised do
        LuminWestBengalSms::setup_table(@db)
      end
    end

  end
  
end

unless ARGV.length == 2
  puts "USAGE: csv_to_sql.rb CSVFILE SQLITENAME"
  exit(1)
end

csv_file = ARGV.first
sqlite_file = ARGV.last

#include LuminWestBengalSms
db = LuminWestBengalSms::create_db(sqlite_file)
LuminWestBengalSms::setup_table(db)
cols, data = LuminWestBengalSms::process_csv(csv_file)
LuminWestBengalSms::write_table(db, cols, data)
