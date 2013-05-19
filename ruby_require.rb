# best:
# relative to current file, find all ruby files
# then strip the ".rb" extension before calling "require"
Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each do |file| 
    require File.basename(file, File.extname(file))
end

