module Clomp
  class Result
    attr_reader :options, :operation, :state
    
    def initialize(options: {}, tracks: [], operation: nil)
      @report = {}
      
      @operation      = set_prop :operation, operation || Operation.new
      @tracks         = set_prop :tracks, tracks || []
      @options        ||= {}
      @immutable_data = set_prop :options, options
      @state          = ->(tracks) { tracks.select {|track| track.failure?}.count.zero? }
    end
    
    def success?
      @state.(self[:tracks]) === true
    end
    
    def failure?
      @state.(self[:tracks]) === false
    end
    
    def method_missing(method, *args)
      if @operation.respond_to?(method)
        @operation.send(method, *args)
      else
        super
      end
    end
    
    def [](key)
      sym_key = to_sym_key(key)
      
      self.instance_variable_get(sym_key)
    end
    
    def []=(key, value)
      sym_key = to_sym_key(key)
      self.instance_variable_set(sym_key, value)
    end
    
    def set_prop(key, value)
      sym_key = to_sym_key(key)
      
      self.instance_variable_set(sym_key, value)
    end
    
    private
    
    def to_sym_key(key)
      if key.is_a? Symbol
        ('@' + key.to_s).to_sym
      else
        ('@' + key.to_s.delete('@')).to_sym
      end
    end
  end
end