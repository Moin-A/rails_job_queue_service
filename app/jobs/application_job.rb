class ApplicationJob < ActiveJob::Base
  def self.perform_async(*args)
    Job.perform_async(name, *args)
  end
end
