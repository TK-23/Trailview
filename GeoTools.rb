def find_center(points)
  min_x = points[0][0]
  min_y = points[0][1]
  max_x = points[0][0]
  max_y = points[0][1]

  points.each do |point|
    max_x = point[0] if point[0] > max_x
    min_x = point[0] if point[0] < min_x
    max_y = point[1] if point[1] > max_y
    min_y = point[1] if point[1] < min_y
  end

  avg_x = ( max_x + min_x ) / 2
  avg_y = ( max_y + min_y ) / 2

  result = [ avg_x, avg_y ]
end

