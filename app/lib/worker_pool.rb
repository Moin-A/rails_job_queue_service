class WorkerPool
  def initialize(concurrency: JobQueue.config.concurrency)
    @concurrency = concurrency
    @threads = []
  end

  def start
    @concurrency.times do
      @threads << Thread.new { }
    end
  end

  def thread_count
    @threads.count
  end
end
