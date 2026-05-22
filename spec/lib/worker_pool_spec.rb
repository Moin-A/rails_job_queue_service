require "rails_helper"

class TestJob < ApplicationJob
  def perform(*args); end
end

class FailingJob < ApplicationJob
  def perform
    raise "something went wrong"
  end
end

RSpec.describe WorkerPool do
  describe "#start" do
    it "creates threads equal to configured concurrency" do
      JobQueue.configure { |config| config.concurrency = 3 }
      pool = WorkerPool.new(concurrency: JobQueue.config.concurrency)

      pool.start

      expect(pool.thread_count).to eq(3)
    end
  end

  describe "#process" do
    let(:pool) { WorkerPool.new(concurrency: 1) }

    it "executes the job and marks it as completed" do
      job = Job.create!(job_class: "TestJob", args: '["hello"]', status: "running")

      pool.send(:process, job, 1)

      expect(job.reload.status).to eq("completed")
    end
  end

  describe "#process" do
    let(:pool) { WorkerPool.new(concurrency: 1) }

    it "calls handle_failure when the job raises an error" do
      job = Job.create!(job_class: "FailingJob", args: "[]", status: "running", attempts: 0, max_attempts: 3)

      pool.send(:process, job, 1)

      expect(job.reload.status).to eq("pending")
      expect(job.reload.attempts).to eq(1)
      expect(job.reload.last_error).to eq("something went wrong")
    end
  end

  describe "#handle_failure" do
    let(:pool)  { WorkerPool.new(concurrency: 1) }
    let(:error) { RuntimeError.new("something went wrong") }

    it "increments attempts and resets to pending when attempts < max_attempts" do
      job = Job.create!(job_class: "TestJob", args: "[]", status: "running", attempts: 0, max_attempts: 3)

      pool.send(:handle_failure, job, error, 1)

      expect(job.reload.status).to eq("pending")
      expect(job.reload.attempts).to eq(1)
    end

    it "marks job as dead when attempts reach max_attempts" do
      job = Job.create!(job_class: "TestJob", args: "[]", status: "running", attempts: 2, max_attempts: 3)

      pool.send(:handle_failure, job, error, 1)

      expect(job.reload.status).to eq("dead")
    end

    it "stores the error message in last_error" do
      job = Job.create!(job_class: "TestJob", args: "[]", status: "running", attempts: 0, max_attempts: 3)

      pool.send(:handle_failure, job, error, 1)

      expect(job.reload.last_error).to eq("something went wrong")
    end
  end

  describe "#work_loop" do
    it "picks up a pending job and processes it to completion" do
      job  = TestJob.perform_async("hello")
      pool = WorkerPool.new(concurrency: 1)

      pool.start
      sleep 0.1 # give thread time to process

      expect(job.reload.status).to eq("completed")

      pool.stop
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
