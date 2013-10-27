#select email, users.id, users.created_at from users where users.id in 
#();

query_string = "SELECT user_id FROM `kids` " 
query_string += "WHERE `created_at` > '2013-09-14 17:38:39' and created_at < '2013-09-18 17:38:39' "
query_string += "and birthday != '2008-01-01' and name like '%Alexis%'"

##
"SELECT user_id FROM `kids` WHERE `created_at` > '2013-09-10 17:38:39' and created_at < '2013-09-14 17:38:39' and birthday != '2008-01-01' and name like '%Alexis%'"
###
results = ActiveRecord::Base.connection.execute(query_string);
puts "rows..."
user_ids = []
results.each do |row|
  puts "#{row.inspect}"
  user_ids << row.first.to_s
end

user_ids = %w/
6054149
3207471
1829191
4798589
6055971
6056647
6056906
6057080
6058943
6059111
6046561
6061222
6065839
6066576
6067390
6065148
6067921
6068351
6068356
6068507
6068699
6068748
6069375
6071673
6071996
6072049
6073783
6076900
/
["6054149", "3207471", "1829191", "4798589", "6055971", "6056647", "6056906", "6057080", "6058943", "6059111", "6046561", "6061222", "6065839", "6066576", "6067390", "6065148", "6067921", "6068351", "6068356", "6068507", "6068699", "6068748", "6069375", "6071673", "6071996", "6072049", "6073783", "6076900"]
