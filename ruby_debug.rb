# https://minhajuddin.com/2016/03/03/put-this-in-your-code-to-debug-anything/?utm_source=rubyweekly&utm_medium=email
class Object
  def dbg
    self.tap {|x| puts ">>>>>>>>>>>>>"; puts x; puts "<<<<<<<<<<<<<"; }
  end
end

get_csv = [{id_col: "one"}, {id_col: "two"}, {id_col: "three"}]
row_id = "three"

# get_csv.find {|x| x[:id_col] == row_id }
# =>
get_csv.dbg.find {|x| x[:id_col.dbg] == row_id.dbg }.dbg

