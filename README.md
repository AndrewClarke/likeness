# likeness
Returns a string similarity factor using a powerful similarity algorithm
The method used is far superior to Levenshtein etc for realistic text.
Read the Simon White article (referenced below) to understand the science.

NOTE: This algoritm has worked very well for me,
but this Gem needs unit tests, doco, cleanup of this readme and better samples
before it can leave release candidate status.

This gem is directly inspired by a
[Stack Overflow Q&A](http://stackoverflow.com/questions/653157/a-better-similarity-ranking-algorithm-for-variable-length-strings)
which references
[Simon White of Catalysoft](http://www.catalysoft.com/articles/StrikeAMatch.html)
in the response.

Release 1.0.0 offers

```ruby
measure = similarity(str1, str2, width: 2, splitter: /\W+/) { |str| str.downcase.gsub(/(?<=\w)'/, '') }
# TODO: correct method list.
```

where the width and splitter defaults are shown,
and the optional block shows the standard canonicaliser.

The splitter (default /\W+/ which means 'non-word characters')
allows you to choose how to break up the string into words or packets.
The default splitter of /\W+/ means that punctuation will also be ignored.

The process of canonicalisation refers to removing junk or
other characters you don't care about.
You might consider punctuation characters are worth keeping, for example.
The default canonicaliser downcases the string and strips apostrophes embedded in a word or trailing a word.
If you only wish to downcase the string, pass &:downcase.
If you do not even want that, pass a null block { |s| s }

The default width of 2 refers to the size of the 'shingles'
that each word is split up into.
The article uses shingles of length 2,
but you might find it useful to go for bigger shingle sizes depending on your data.
Be very sure you understand both the method and your data before using a larger
shingle size, because the larger the shingle,
the less there will be collatable fragments worth counting.

The canonicaliser block is first applied to each string,
then the string is broken into words using the splitter,
and finally the algorithm performs its magic to rate the difference
between the two sets of cleaned-up words.

The resultant measure ranges from 0.0 to 1.0.
Strings that are completely different will rate 0.0,
and strings that are completely identical
(disregaring variations of whitespace)
will measure as equivalent (1.0).
The default settings for canonicalisation means that
empty strings or strings containing only blanks
are all equivalent.

## Constructor samples

```ruby
require 'likeness'

# Everything defaulted
compar = Likeness.new

# My data is very samey, I'll try bigger shingles.
compar = Likeness.new(width: 3)

# Ignore digits - so split on them will do the trick...
compar = Likeness(splitter: /[\d\W]+/)

# I only want to downcase. Apostrophes can split the words
compar = Likeness { |str| str.downcase }

# A short-form of the previous downcase option
compar = Likeness(&:downcase)

# I am reading a CSV, and all characters need to be significant.
# Even uppercase is significant, so pass a no-op kind of block.
# NOTE: this is actually a weak way to split CSV files. Sigh.
compar = Likeness(splitter: /,/) { |str| str }
```

## Comparison samples

```ruby
require 'likeness'

compar = Likeness.new   # using the defaults for the examples

compar.match("abcdefg", "acdeg")  => 0.4
compar.match("abcdefg", "abcefg") => 0.7272727272727273
compar.match("abcdefg", "ABCDFG") => 0.7272727272727273
compar.match("abcdefg", "abcdef") => 0.9090909090909091
compar.match("abcdefg", "abcdefg") => 1.0
compar.match("ABCDEFG", "abcdefg") => 1.0
```

## Comparison samples using the short-form

```ruby
require 'likeness'

compar = Likeness.new   # using the defaults for the examples

compar["abcdefg", "acdeg"]  => 0.4
compar["abcdefg", "abcefg"] => 0.7272727272727273
compar["abcdefg", "ABCDFG"] => 0.7272727272727273
compar["abcdefg", "abcdef"] => 0.9090909090909091
compar["abcdefg", "abcdefg"] => 1.0
compar["ABCDEFG", "abcdefg"] => 1.0
```

## Creating a Subject object

```ruby
require 'likeness'

compar = Likeness.new   # using the defaults for the examples
FACTOR = 0.6

list_of_1_thousand_words.each do |str1|
  sub = compar.subject(str1)
  list_of_2_thousand_words.select { |str2| sub.match(str2) > FACTOR }.each do |str2|
    big_function(str1, str2)
  end
end
```

