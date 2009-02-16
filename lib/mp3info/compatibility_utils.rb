# encoding: binary
#
# Utilities for making it easier to support both Ruby 1.8 and Ruby 1.9. Will
# wither as I learn better conventions for these things -- I hope.

# In Ruby 1.9, slice is more consistent and returns a single-character
# string, so the new String.ord method must be used to produce the
# ordinal value of the character.
class String
  def to_ordinal
    self.ord
  end
end

class Fixnum
  def to_ordinal
    self
  end
end