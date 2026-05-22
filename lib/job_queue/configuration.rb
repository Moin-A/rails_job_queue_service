module JobQueue
  class Configuration
    attr_accessor :concurrency, :poll_interval, :max_attempts

    def initialize
      @concurrency   = 5
      @poll_interval = 2
      @max_attempts  = 3
    end
  end
end
