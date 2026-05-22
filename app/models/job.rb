class Job < ApplicationRecord
  STATUSES = %w[pending running completed failed dead].freeze

  validates :job_class, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :running, -> { where(status: "running") }
  scope :failed,  -> { where(status: "failed") }
  scope :dead,    -> { where(status: "dead") }

  def self.perform_async(job_class, *args)
    create!(
      job_class: job_class.to_s,
      args: JSON.generate(args),
      status: "pending"
    )
  end
end
