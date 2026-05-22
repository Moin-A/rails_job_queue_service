require "test_helper"
require Rails.root.join("lib/job_queue")

class WorkerPoolTest < ActiveSupport::TestCase
  test "start creates threads equal to configured concurrency" do
    JobQueue.configure { |config| config.concurrency = 3 }
    pool = WorkerPool.new(concurrency: JobQueue.config.concurrency)

    pool.start

    assert_equal 3, pool.thread_count
  end
end
