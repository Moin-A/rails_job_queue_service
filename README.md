# Rails Job Queue Service

A Sidekiq-style background job processor built on top of Rails and SQLite. Jobs are persisted to the database and picked up by a thread-pool worker.

---

## Architecture

| Component | Location | Purpose |
|---|---|---|
| `Job` model | `app/models/job.rb` | ActiveRecord-backed queue (SQLite) |
| `ApplicationJob` | `app/jobs/application_job.rb` | Base class all jobs inherit from |
| `WorkerPool` | `app/lib/worker_pool.rb` | Thread pool — claims and processes jobs |
| `JobQueue::Configuration` | `lib/job_queue/configuration.rb` | Config object (concurrency, poll interval, max attempts) |
| `bin/job` | `bin/job` | Entry point — boots Rails and starts the worker |

---

## Configuration

Set in `config/initializers/job_queue.rb`, overridable via environment variables:

```ruby
JobQueue.configure do |config|
  config.concurrency   = ENV.fetch("WORKER_CONCURRENCY", 5).to_i
  config.poll_interval = ENV.fetch("WORKER_POLL_INTERVAL", 2).to_i
  config.max_attempts  = ENV.fetch("WORKER_MAX_ATTEMPTS", 3).to_i
end
```

---

## Creating a Job

Inherit from `ApplicationJob` and define a `perform` method:

```ruby
# app/jobs/my_job.rb
class MyJob < ApplicationJob
  def perform(arg1, arg2)
    # your logic here
  end
end
```

---

## Enqueueing Jobs

`Job` is an ActiveRecord model — accessible from anywhere in Rails (controllers, console, other models, etc.).

**From a controller or console:**
```ruby
MyJob.perform_async("hello", 42)
```

This inserts a row into the `jobs` table with `status: "pending"`. The worker picks it up on its next poll.

### How `perform_async` works

Calling `MyJob.perform_async` goes through two layers:

```
MyJob.perform_async("hello", 42)
  → ApplicationJob.perform_async("hello", 42)   # inherited class method
    → Job.perform_async("MyJob", "hello", 42)   # writes the DB row
```

`ApplicationJob.perform_async` passes the job class name and args to `Job.perform_async`, which is the method that actually creates the database record. You can also call `Job.perform_async` directly if you have the class name as a string:

```ruby
Job.perform_async("MyJob", "hello", 42)
```

---

## Starting the Worker

```bash
bundle exec ruby bin/job
```

The worker starts a thread pool, polls for pending jobs, and processes them. Stop it with `Ctrl+C`.

---

## Quick End-to-End Test

A `WriteFileJob` is included for manual testing. It appends a timestamped line to `/tmp/job_output.txt`.

**1. Start the worker in one terminal:**
```bash
bundle exec ruby bin/job
```

**2. Enqueue the job from the Rails console:**
```bash
bundle exec rails console
```
```ruby
WriteFileJob.perform_async("hello from console")
```

**3. Verify it ran:**
```bash
cat /tmp/job_output.txt
# => [2026-05-22 18:02:25 +0530] WriteFileJob ran: hello from console
```

---

## Running the Specs

```bash
bundle exec rspec
```

Key spec files:

| File | Covers |
|---|---|
| `spec/lib/worker_pool_spec.rb` | `#start`, `#process`, `#handle_failure`, `#claim_job`, `#work_loop` integration |
| `spec/models/application_job_spec.rb` | Job enqueueing via `perform_async` |
