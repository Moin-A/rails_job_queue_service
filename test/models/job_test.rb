require "test_helper"

class JobTest < ActiveSupport::TestCase
  test "perform_async creates a pending job with correct attributes" do
    job = Job.perform_async("EmailJob", "user@example.com", "Hello")

    assert job.persisted?
    assert_equal "EmailJob", job.job_class
    assert_equal '["user@example.com","Hello"]', job.args
    assert_equal "pending", job.status
    assert_equal 0, job.attempts
    assert_equal 3, job.max_attempts
    assert_nil job.last_error
  end

  test "perform_async stores args as JSON array" do
    job = Job.perform_async("SomeJob", 1, 2, 3)

    assert_equal [1, 2, 3], JSON.parse(job.args)
  end

  test "perform_async works with no args" do
    job = Job.perform_async("NoArgJob")

    assert_equal "[]", job.args
  end

  test "pending scope returns only pending jobs" do
    Job.perform_async("EmailJob")
    Job.create!(job_class: "OtherJob", args: "[]", status: "completed")

    assert_equal 1, Job.pending.count
    assert Job.pending.all? { |j| j.status == "pending" }
  end

  test "dead scope returns only dead jobs" do
    Job.create!(job_class: "DeadJob", args: "[]", status: "dead")
    Job.perform_async("LiveJob")

    assert_equal 1, Job.dead.count
  end

  test "job_class cannot be blank" do
    job = Job.new(job_class: "", args: "[]")

    assert_not job.valid?
  end
end
