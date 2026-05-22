require "rails_helper"

class TestJob < ApplicationJob
  def perform(name)
  end
end

RSpec.describe ApplicationJob do
  describe ".perform_async" do
    it "inserts a pending job record into the database" do
      TestJob.perform_async("Alice")

      job = Job.last
      expect(job.job_class).to eq("TestJob")
      expect(JSON.parse(job.args)).to eq(["Alice"])
      expect(job.status).to eq("pending")
    end
  end
end
