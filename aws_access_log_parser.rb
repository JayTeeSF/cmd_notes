# create a csv
grep -r '404 404' * |
  awk '{ print $1 ":" $3 ":" $13 }' |
  awk -F: '{ print $5 "," $2":"$3":"$4","$7":"$8$9 }' |
  sort >~/Desktop/offending_ips.csv
  # or, instead of using pivot-tables, group by ip:
  # ruby -ne 'BEGIN{ h = {}}; (ip,date_time,url) = $_.split(","); h[ip] ||= []; h[ip] << {date_time: date_time, url: url}; END{ h.each_pair {|ip, dtus| puts ip; dtus.each {|dtu| puts "\t@ #{dtu[:date_time]} => #{dtu[:url]}"} }}' > ~/Desktop/offenders_filtered.txt

