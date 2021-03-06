module Clomp
  class Operation
    attr_reader :result, :configs
    
    # Constructor for operation object
    #
    # @param track_builders [Array] the list of tracks we define
    # @param options [Hash] of options to be provided by .[] call/method
    # @return [self]
    def initialize(track_builders: [], options: {}, exec: true)
      @options = options
      # Setup result object!
      @result = Result.new(
          operation: self,
          tracks:    track_builders || [],
          options:   options || {}
      )
      
      @configs = self.class.setup_configuration
      
      exec_steps! if exec
    end
    
    # Execute all the steps! Execute all the tracks!
    def exec_steps!
      Executor[result, @options, _self: self]
    end
    
    def executed_steps
      @result['tracks'].collect {|track| track.name if track.success?}.compact
    end
    
    # Name of the steps defined in the operation class
    def steps
      @result['tracks'].collect {|track| track.name}
    end
    
    class << self
      
      # To store and read all the tracks!
      attr_accessor :track_builders, :configs
      
      # Operation wise configuration to control state
      # All operation may not require fail fast
      # All operation may not require pass fast
      # Operation wise optional value could be different
      #
      # @yield [config] to mutate new configuration
      #
      # @return [Configuration] @config
      def setup
        @configs ||= Configuration.new
        
        yield(@configs) if block_given?
        
        @configs
      end
      
      alias_method :setup_configuration, :setup
      
      # Share track from other operation
      def share(track_name, from:, track_options: {}, &block)
        @track_builders ||= []
  
        _callable_class = from && from.kind_of?(String) ? Object.const_get(from) : from
        
        raise UnknownOperation, 'Please provide a valid operation to share the steps for' unless _callable_class
        
        @track_builders << build_track(track_name, track_options, :track, track_for: _callable_class , &block)
      end
      
      # get track name and options!
      def track(track_name, track_options: {}, &block)
        @track_builders ||= []
        
        @track_builders << build_track(track_name, track_options, :track, track_for: nil, &block)
      end
      
      # get the track name for the failure case!
      def failure(track_name, track_options: {}, &block)
        @track_builders ||= []
        
        @track_builders << build_track(track_name, track_options, :failed_track, track_for: nil, &block)
      end
      
      # get the track name for the final step! Only one step will be executed!
      def finally(track_name, track_options: {}, &block)
        @track_builders ||= []
        
        @track_builders << build_track(track_name, track_options, :finally, track_for: nil, &block)
      end
      
      def [](mutable_data = {}, immutable_data = {})
        self.(mutable_data, immutable_data)
      end
      
      def call(mutable_data = {}, immutable_data = {})
        new(
            track_builders: @track_builders,
            options:        {
                mutable_data:   mutable_data,
                immutable_data: immutable_data
            },
            ).result
      end
      
      private
      
      def build_track(track_name, track_options = {}, track_type, track_for: nil, &block)
        @configs ||= Configuration.new
        
        TrackBuilder[track_name: track_name, track_options: track_options, track_type: track_type, track_for: track_for, &block]
      end
    end
  end
end