class WriteFileJob < ApplicationJob
  def perform(message = "hello")
    File.open("/tmp/job_output.txt", "a") do |f|
      f.puts "[#{Time.now}] WriteFileJob ran: #{message}"
    end
  end
end
