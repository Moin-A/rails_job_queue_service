require_relative "job_queue/configuration"

module JobQueue
  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end
end
