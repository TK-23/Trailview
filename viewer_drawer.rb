

def create_section()
  width = 100
  start_coord = [long, lat]
  degree = 45
  degree_buffer = 10
  degree_increment = 0.5

  degree_span_start = degree - degree_buffer
  degree_span_end = degree + degree_buffer

  current_degree = degree_span_start
  while current_degree != degree_span_end
    radian = current_degree * ( Math::PI / 180 )

    x = width *  Math.cos(radian).round(10)
    y = width * Math.sin(radian).round(10)

    current_degree += degree_increment
    puts "#{x} #{y}"
  end
end
