
class Likeness
  # Yields an object that can be used to compare many strings.
  def initialize(options = {}, &cleaner)
    # Collect or default the size of shingles to extract from each word.
    @width = options[:width] || 2

    # splitter can be a Regexp (defaults to any non-word) or a proc/lambda for extra power.
    # The caller can split on strict whitespace by passing /\s+/, whereas the default of
    # /\W+/ basically only leaves alpha-num. "Apostrophe's" (sic) could be an issue...
    #
    # Capture as both, then replace splitter with a lambda-wrap of re if it is a pattern.
    re = @splitter = options[:splitter] || /\W+/
    @splitter = lambda { |str| str.split(re) } if Regexp === re

    # Give caller the opportunity to use a canonicalizing block.
    # If the caller wants no lower-casing, they can use a no-op block { |s| s } :p
    # If the caller does not want to quietly ignore apostrope's, then pass (&:downcase)
    @cleaner ||= lambda { |str| str.downcase.gsub(/(?<=\w)'/, '') }
  end  # initialize


  def self.match(shingles1, shingles2)
    n = (l1 = shingles1.length) + (l2 = shingles2.length)
    # Two empty strings match perfectly. NOTE: strings full of separator also appear empty.
    return 1.0 if n == 0

    # Count matching shingles. Exploit the sorted lists returned from smush() to step through them both.
    i1 = i2 = k = 0
    while i1 < l1 && i2 < l2
        case
          when shingles1[i1] < shingles2[i2] then i1 += 1     # step forward in shingles1 while its current shingle is behind
          when shingles1[i1] > shingles2[i2] then i2 += 1     # ditto for shingles2
          else i1 += 1; i2 += 1; k += 1       # score!!!
        end
    end

    # Final score ranges from 0.0 to 1.0
    return (2.0 * k) / n
  end  # self.match


  def match(str1, str2)
    # Split into words, then collect progressive shingles from each word. Result will be a flat sorted list of shingles.
    return Likeness::match(shingles(str1), shingles(str2))
  end  # match

  alias_method :[], :match    # a sussinct alternative to .match


  def shingles(str)
    return @splitter.call(@cleaner.call(str))
                  .reject(&:empty?)
                     .map{ |s| s.length < @width ? s : 0.upto(s.length - @width).collect { |i| s[i, @width] } }
                 .flatten
                    .sort
  end  # shingles
end  # Likeness::

