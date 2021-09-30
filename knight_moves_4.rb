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

# Generate an array of possible total moves that would still allow for a solution
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

# Returns an array of arrays of arrays.
# This represents a list of all possible ways to split up the cell values such
#   that they meet the criteria for a possible solution.
# CHRIS -- So how brute-forcey do I want to make this thing?
#          As little as possible, I guess, but where shall I settle...?

# First thing we need to do is find just one possible partitioning for each
#   given possible number of moves in poss_ms.
#
def calc_root_partition(r, m)
  total_per_r = ((m * (m + 1)) / 2) / r
  puts "total_per_r = " + total_per_r.to_s
  root_partition = Array.new(m, -1)
  region_totals = Array.new(r, 0)
  i = m
  while i > 0 do
    for j in 0..r-1 do
      if (region_totals[j] + i <= total_per_r)
        region_totals[j] += i
        root_partition[i-1] = j
        break
      end
    end
    i = (i - 1)
  end
  return root_partition
end

def calc_poss_partitions(r_num_cells, poss_ms)

end

grid_data = read_input_file
grid_metadata = parse_grid_metadata(grid_data)
region_data = parse_region_data(grid_data, grid_metadata)
moves_data = parse_moves_data(grid_data, grid_metadata)
moves_data[:poss_ms] = determine_possible_num_moves(grid_metadata, region_data, moves_data)
moves_data[:poss_ms].each do |m|
  root_partition = calc_root_partition(region_data[:num_regions], m)
  puts "Root partition for " + m.to_s + " moves: " + root_partition.to_s
end
# poss_partitions = calc_poss_partitions(region_data[:r_num_cells], moves_data[:poss_ms])
