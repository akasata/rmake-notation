# util.rb is inspired by ActiveSupport

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

class NilClass
  def blank?
    true
  end
end

class FalseClass
  def blank?
    true
  end
end

class TrueClass
  def blank?
    false
  end
end

class Array
  alias_method :blank?, :empty?
end

class Hash
  alias_method :blank?, :empty?
end

class String
  def blank?
    self !~ /[^[:space:]]/
  end
end

class Numeric #:nodoc:
  def blank?
    false
  end
end

module Rmake::Util
end
