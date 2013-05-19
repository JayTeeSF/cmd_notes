# best:
# relative to current file, find all ruby files
# then strip the ".rb" extension before calling "require"
Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each do |file| 
    file_base = File.basename(file, File.extname(file))
    file_dirname = File.dirname(file)
    require_path = "#{file_dirname}/#{file_base}"
    require require_path
end

