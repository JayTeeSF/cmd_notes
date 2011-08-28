# irb -r clusters.rb
# Clusters.instance_methods #=> [:matrix, :height, :max_y, :max_x, :width, :get, :[], :filled?]
# Clusters.height #=> 9
# Clusters.width #=> 16
# Clusters.max_y #=> 8
# Clusters.max_x #=> 15
# Clusters.matrix # => [[...],[....],...etc]
# Clusters[0,1] #=> "."
# Clusters.filled?(0,1) #=> true
# Clusters[5,1] #=> ""
# Clusters.filled?(5,1) #=> false

module Clusters
  extend self

  DOT = '.'
  NON = ''
  def matrix
    [
      [DOT, DOT, DOT, DOT, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON],
      [DOT, DOT, DOT, DOT, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON],
      [DOT, DOT, DOT, DOT, NON, NON, DOT, DOT, DOT, DOT, NON, NON, NON, NON, NON, NON],
      [DOT, DOT, DOT, DOT, NON, NON, DOT, DOT, DOT, DOT, NON, NON, NON, NON, NON, NON],
      [NON, NON, NON, NON, NON, NON, DOT, DOT, DOT, DOT, NON, NON, NON, NON, NON, NON],
      [NON, NON, NON, NON, NON, NON, DOT, DOT, DOT, DOT, NON, NON, DOT, DOT, DOT, DOT],
      [NON, NON, NON, NON, NON, NON, DOT, DOT, DOT, DOT, NON, NON, DOT, DOT, DOT, DOT],
      [NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, DOT, DOT, DOT, DOT],
      [NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, NON, DOT, DOT, DOT, DOT],
    ]
  end

  def height
    matrix.length
  end

  def max_y
    height - 1
  end

  def max_x
    width - 1
  end

  def width
    matrix[0].length
  end

  # down V, across->
  def get y, x
    matrix[y][x]
  end
  alias :[] :get

  def filled? y, x
    ! get(y, x).empty?
  end
end
