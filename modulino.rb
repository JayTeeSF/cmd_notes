# Back in my Perl days I read an article about making modules function as standalone programs (based on whether or not they were called on the command line).
# While reading some Ruby code today (logstash/agent.rb) I rediscovered this concept:

# Simply end your ruby code with:

if __FILE__ == $0
  # ...run the code in this file...
end
