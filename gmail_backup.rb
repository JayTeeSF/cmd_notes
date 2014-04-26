#gem install gmail
# modify code (bug):
#mvim `gem which gmail`
# #require 'mime/message' #comment-out this line from gmail/message.rb

require 'gmail'
gmail = Gmail.new('jonathan@zoodles.com', 'x3c4dsaw')

mbox = gmail.mailbox("[Gmail]/Sent Mail")

sent_messages = mbox.emails; 0

# each message can:
# =>
# [:uid, :flag, :unflag, :mark, :spam!, :read!, :unread!, :star!, :unstar!, :delete!, :archive!, :move_to, :move, :move_to!,
# :move! , :label, :label!, :add_label, :add_label!, :remove_label!, :delete_label!, :inspect, :method_missing, :respond
# as well as:
# sent_messages.first.subject
# sent_messages.first.body

require "fileutils"
@mail_dir = "./sent_mail"
FileUtils.mkdir_p @mail_dir

def pretty(string)
  return string.dup.gsub(/[^A-Za-z0-9\_\-]/, '_')
end

sent_messages.each do |email|
   mail_file_prefix = "#{@mail_dir}/#{pretty(email.subject)}_#{Time.parse(email.date).to_i}"
   mail_file_suffix = "mbx"
   mail_file = "#{mail_file_prefix}.#{mail_file_suffix}"

  if !email.message.attachments.empty?
    attachment_dir = mail_file_prefix
        #email.message.save_attachments_to(attachment_dir)
    email.message.attachments.each do |attachment|
    file = File.new(attachment_dir + attachment.filename, "w+")
    file << attachment.decoded
    file.close
end
  end

   File.open(mail_file, "w+") {|f| f.puts email.raw_message}
end

