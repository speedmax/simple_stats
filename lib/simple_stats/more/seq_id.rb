module SimpleStats
  # Time-based UUID class
  #   - Better couchdb performance and less storage
  #   - id includes timestamp (Javascript date class compatible)
  #   Credit: from couchtiny http://github.com/candlerb/couchtiny
  class SeqID #:nodoc:
    RAND_SIZE = (1<<64) - (1<<32)  #:nodoc:

    def initialize
      @ms = (::Time.now.to_f * 1000.0).to_i   # compatible with Javascript Date
      @pid = (Process.pid rescue rand(65536)) & 0xffff
      @seq = nil
    end

    def call
      @seq = @seq ? (@seq+1) : rand(RAND_SIZE)
      sprintf("%012x%04x%016x", @ms, @pid, @seq)
    end
  end
end