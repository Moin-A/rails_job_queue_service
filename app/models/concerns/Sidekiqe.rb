module Sidekiq
    include ActiveSupport::Concern
        
    class_methods do
        def perform_async(*args)
            # Custom logic for enqueuing jobs
        end
    end
end