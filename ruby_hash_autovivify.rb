# owing to my days of Perl, I like the following method:
def autovivifying_hash(depth=0)
  return Hash.new if 0 == depth
  Hash.new { |ht,k| ht[k] =autovivifying_hash(depth - 1) }
end

i.e.
normal_h = autovivify_hash
deeper_h = autovivify_hash(2)

## or, better yet:

Hash.new {|h,k| h[k] = Hash.new(&h.default_proc) }
