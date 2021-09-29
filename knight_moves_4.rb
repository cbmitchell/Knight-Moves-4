#!/usr/bin/ruby

# Print out the board
def print_board (board)
  board.each do |row|
    puts row.to_s
  end
end

# Open input txt file containing grid info
gridfile_name = ARGV[0]
puts gridfile_name
grid_data = File.read(gridfile_name).split

# CHRIS -- Screw it. I'm just going to assume the order of the stuff in the file.
x = grid_data[0].to_i
y = grid_data[1].to_i
r_start = 2               # r_start - first line of the input file describing the regions
r_end = r_start + y - 1   # r_end   - last line of the input file describing the regions
m_start = r_end + 1
m_end = m_start + y - 1
puts "r_start = " + r_start.to_s
puts "r_end = " + r_end.to_s
puts "m_start = " + m_start.to_s
puts "m_end = " + m_end.to_s

puts "Reading region data..."
regions = Array.new(y) {|e| e = Array.new(x, -1)}
for i in r_start..r_end do
  cells = grid_data[i].split(',')
  for j in 0..x-1 do
    regions[i-2][j] = cells[j].to_i
  end
end
print_board(regions)
puts

puts "Reading moves data..."
moves = Array.new(y) {|e| e = Array.new(x, -1)}
for i in m_start..m_end do
  cells = grid_data[i].split(',')
  for j in 0..x-1 do
    moves[i-1-r_end][j] = cells[j].to_i
  end
end
print_board(moves)
puts
