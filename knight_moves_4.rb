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
  x = grid_data[0].strip.to_i
  y = grid_data[1].strip.to_i
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
  r_labels = []
  r_num_cells = []
  for i in gm[:r_start]..gm[:r_end] do
    cells = gd[i].strip.split(',')
    for j in 0..gm[:x]-1 do
      if not r_labels.include? cells[j]
        r_labels.push(cells[j])
        r_num_cells.push(0)
      end
      new_label = r_labels.find_index(cells[j])
      r_num_cells[new_label] += 1
      regions[i-2][j] = new_label.to_i
    end
  end
  num_regions = r_labels.length
  puts "num_regions = " + num_regions.to_s
  puts "r_num_cells = " + r_num_cells.to_s
  print_board(regions)
  puts
  region_data = {
    regions: regions,         # 2D array representing regions
    num_regions: num_regions, # number of different regions
    r_num_cells: r_num_cells  # number of cells belonging to region (by index)
  }
end

# Parse moves data from input file based on parsed metadata
def parse_moves_data(gd, gm)
  puts "Parsing moves data..."
  max_val = 0
  moves = Array.new(gm[:y]) {|e| e = Array.new(gm[:x], -1)}
  for i in gm[:m_start]..gm[:m_end] do
    cells = gd[i].strip.split(',')
    for j in 0..gm[:x]-1 do
      moves[i-1-gm[:r_end]][j] = cells[j].to_i
      if cells[j].to_i > max_val
        max_val = cells[j].to_i
      end
    end
  end
  puts "max_val = " + max_val.to_s
  print_board(moves)
  puts
  moves_data = {
    moves: moves,     # 2D array representing positions of known cell values
    max_val: max_val  # highest known cell value provided in the input file
  }
end

def go_for_it
  grid_data = read_input_file
  grid_metadata = parse_grid_metadata(grid_data)
  region_data = parse_region_data(grid_data, grid_metadata)
  moves_data = parse_moves_data(grid_data, grid_metadata)
end

# Okay, so now I finally have all the logic in place to actually start doing
#   the part that I started this thing for in the first place.
# So, how shall I go about this...

def determine_possible_num_moves(gm, rd, md)
  puts "Determining possible total moves..."
  min = md[:max_val]
  max = gm[:x] * gm[:y]
  poss_ms = []
  for i in min..max do
    if i % rd[:num_regions] == 0 or (i + 1) % rd[:num_regions] == 0
      poss_ms.push(i)
    end
  end
  puts "poss_ms = " + poss_ms.to_s
  return poss_ms
end

grid_data = read_input_file
grid_metadata = parse_grid_metadata(grid_data)
region_data = parse_region_data(grid_data, grid_metadata)
moves_data = parse_moves_data(grid_data, grid_metadata)
moves_data[:poss_ms] = determine_possible_num_moves(grid_metadata, region_data, moves_data)
