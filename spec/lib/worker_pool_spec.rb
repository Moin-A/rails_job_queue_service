require "rails_helper"

RSpec.describe WorkerPool do
  describe "#start" do
    it "creates threads equal to configured concurrency" do
      JobQueue.configure { |config| config.concurrency = 3 }
      pool = WorkerPool.new(concurrency: JobQueue.config.concurrency)

      pool.start

      expect(pool.thread_count).to eq(3)
    end
  end

  describe "#claim_job" do
    let(:pool) { WorkerPool.new(concurrency: 1) }

    it "returns nil when there are no pending jobs" do
      expect(pool.send(:claim_job)).to be_nil
    end

    it "fetches a pending job and marks it as running" do
      job = Job.perform_async("TestJob", "hello")

      claimed = pool.send(:claim_job)

      expect(claimed.id).to eq(job.id)
      expect(job.reload.status).to eq("running")
    end

    it "does not claim an already running job" do
      Job.perform_async("TestJob", "hello")
      pool.send(:claim_job) # marks it running

      expect(pool.send(:claim_job)).to be_nil
    end
  end
end
