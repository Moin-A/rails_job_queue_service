class WorkerPool
  def initialize(concurrency: JobQueue.config.concurrency)
    @concurrency = concurrency
    @threads     = []
    @running     = false
    @mutex       = Mutex.new
    @cond        = ConditionVariable.new
  end

  def start
    @running = true

    @concurrency.times do |i|
      @threads << Thread.new { work_loop(i + 1) }
    end
  end

  def stop
    @running = false
    @mutex.synchronize { @cond.broadcast }
  end

  def thread_count
    @threads.count
  end

  private

  def work_loop(thread_id)
    while @running
      job = claim_job

      if job
        process(job, thread_id)
      else
        @mutex.synchronize { @cond.wait(@mutex, JobQueue.config.poll_interval) }
      end
    end
  end

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
  rescue => e
    handle_failure(job, e, thread_id)
  end

  def handle_failure(job, error, thread_id)
    new_attempts = job.attempts + 1

    if new_attempts >= job.max_attempts
      job.update!(status: "dead", attempts: new_attempts, last_error: error.message)
    else
      job.update!(status: "pending", attempts: new_attempts, last_error: error.message)
    end
  end
end
