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

  private

  def claim_job
    ActiveRecord::Base.transaction do
      job = Job.pending.lock.first
      job&.update!(status: "running")
      job
    end
  end

  def process(job, thread_id)
    klass = job.job_class.constantize
    args  = JSON.parse(job.args)
    klass.new.perform(*args)
    job.update!(status: "completed")
  end
end
