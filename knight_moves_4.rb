#!/usr/bin/ruby

# Print out the board
def print_board (board)
  board.each do |row|
    puts row.to_s
  end
end

# Open input txt file containing grid info
def read_input_file
  gridfile_name = ARGV[0]
  puts gridfile_name
  grid_data = File.read(gridfile_name).split
end

def parse_grid_metadata(grid_data)
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
  grid_metadata = {
    x: x,
    y: y,
    r_start: r_start,
    r_end: r_end,
    m_start: m_start,
    m_end: m_end
  }
end

# Parse region data from input file based on parsed metadata
def parse_region_data(gd, gm)
  puts "Parsing region data..."
  regions = Array.new(gm[:y]) {|e| e = Array.new(gm[:x], -1)}
  for i in gm[:r_start]..gm[:r_end] do
    cells = gd[i].split(',')
    for j in 0..gm[:x]-1 do
      regions[i-2][j] = cells[j].to_i
    end
  end
  print_board(regions)
  puts
  return regions
end

# Parse moves data from input file based on parsed metadata
def parse_moves_data(gd, gm)
  puts "Parsing moves data..."
  moves = Array.new(gm[:y]) {|e| e = Array.new(gm[:x], -1)}
  for i in gm[:m_start]..gm[:m_end] do
    cells = gd[i].split(',')
    for j in 0..gm[:x]-1 do
      moves[i-1-gm[:r_end]][j] = cells[j].to_i
    end
  end
  print_board(moves)
  puts
  return moves
end

grid_data = read_input_file
grid_metadata = parse_grid_metadata(grid_data)
regions = parse_region_data(grid_data, grid_metadata)
moves = parse_moves_data(grid_data, grid_metadata)
