require Rails.root.join("lib/job_queue")

JobQueue.configure do |config|
  config.concurrency   = ENV.fetch("WORKER_CONCURRENCY", 5).to_i
  config.poll_interval = ENV.fetch("WORKER_POLL_INTERVAL", 2).to_i
  config.max_attempts  = ENV.fetch("WORKER_MAX_ATTEMPTS", 3).to_i
end
