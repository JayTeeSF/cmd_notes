My favorite technique for quickly handling "sort_by"
vs. igvita post (http://www.igvita.com/2007/05/08/5-ways-to-sharpen-your-ruby-foo/comment-page-1/#comment-310896):

preferred_order = %w{flute oboe violin}
unordered_ary = %w{oboe violin flute}

     def fast_sort_by(unordered_ary, preferred_order)
       preferred_order & unordered_ary
     end

     vs.
unordered_ary.sort_by{|i| preferred_order.index(i) || 0 }

