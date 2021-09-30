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
  min = [ md[:max_val], rd[:num_regions] * 2 - 1 ].max
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
def calc_root_partition(r, m)
  total_per_r = ((m * (m + 1)) / 2) / r
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

# This function will basically create and traverse a tree of possible partitions
#   with the provided root_partition as the root. The tree doesn't really get
#   persisted, but what does get persisted is every distinct node in the tree.
# This is where things really start to get complicated...
# Anyway, here's the basic outline for this function:
# - Create r arrays,
#   Each array will represent one region of the root partition.
#   These arrays will contain integers representing the values in that region that
#   contribute to the region's sum.
# -

def calc_poss_partitions(r_num_cells, m, root_partition)

  root_partition = normalize_partition(root_partition)
  puts "\nroot_partition    = " + root_partition.to_s
  r = r_num_cells.length

  poss_partitions = Array.new
  poss_partitions.push(root_partition)

  # Create r arrays
  xxs = create_r_arrays_from_partition(r_num_cells, root_partition)

  i_j_combinations = (0...xxs.length).to_a.combination(2).to_a
  i_j_combinations.each do |ij|
    xx_i_combinations = (1...xxs[ij[0]].length).flat_map{|size| xxs[ij[0]].combination(size).to_a}
    xx_j_combinations = (1...xxs[ij[1]].length).flat_map{|size| xxs[ij[1]].combination(size).to_a}
    xx_i_combinations.each do |xx_i_combination|
      xx_i_sum = xx_i_combination.inject(0, :+)
      xx_j_combinations.each do |xx_j_combination|
        xx_j_sum = xx_j_combination.inject(0, :+)
        # CHRIS -- This part is horribly inefficient. I already know some ways
        #          it could be improved, but I just want a proof of concept for
        #          the time being, so maybe I'll come back and optimize later.
        if xx_i_sum == xx_j_sum
          # puts "xx_i_combo = " + xx_i_combination.to_s
          # puts "xx_j_combo = " + xx_j_combination.to_s
          new_partition = create_new_partition(root_partition, xx_i_combination, xx_j_combination)
          # puts "new_partition  = " + new_partition.to_s
          new_partition = normalize_partition(new_partition)
          # puts "new_partition  = " + new_partition.to_s
          if not poss_partitions.include? new_partition
            poss_partitions.push(new_partition)
            puts "poss_partition[" + (poss_partitions.length-1).to_s + "] = " + new_partition.to_s
          end
        end
      end
    end
  end
  return poss_partitions
end

def create_r_arrays_from_partition(r_num_cells, root_partition)
  xxs = Array.new(r_num_cells.length) {|e| e = Array.new}
  for i in 1..root_partition.length
    xxs[root_partition[i-1]].push(i)
  end
  # puts "xxs = " + xxs.to_s
  return xxs
end

def create_new_partition(base_partition, xx_i, xx_j)
  new_partition = base_partition.clone
  i = base_partition[xx_i[0]-1]
  j = base_partition[xx_j[0]-1]
  xx_i.each do |x_i|
    new_partition[x_i-1] = j
  end
  xx_j.each do |x_j|
    new_partition[x_j-1] = i
  end
  return new_partition
end

def normalize_partition(partition)
  r_labels = []
  for i in 0...partition.length
    if not r_labels.include? partition[i]
      r_labels.push(partition[i])
    end
    new_label = r_labels.find_index(partition[i])
    partition[i] = new_label
  end
  return partition
end

# r_labels = []
# r_num_cells = []
# for i in gm[:r_start]..gm[:r_end] do
#   cells = gd[i].strip.split(',')
#   for j in 0..gm[:x]-1 do
#     if not r_labels.include? cells[j]
#       r_labels.push(cells[j])
#       r_num_cells.push(0)
#     end
#     new_label = r_labels.find_index(cells[j])
#     r_num_cells[new_label] += 1
#     regions[i-2][j] = new_label.to_i
#   end
# end

# ——————————————————————————————————————————————————————————————————————————————

grid_data = read_input_file
grid_metadata = parse_grid_metadata(grid_data)
region_data = parse_region_data(grid_data, grid_metadata)
moves_data = parse_moves_data(grid_data, grid_metadata)
moves_data[:poss_ms] = determine_possible_num_moves(grid_metadata, region_data, moves_data)

root_partitions = []
moves_data[:poss_ms].each do |m|
  root_partition = calc_root_partition(region_data[:num_regions], m)
  puts "Root partition for " + m.to_s + " moves: " + root_partition.to_s
  root_partitions.push(root_partition)
end

poss_partitions = []
for i in 0...root_partitions.length do
  poss_partitions.push(calc_poss_partitions(region_data[:r_num_cells], moves_data[:poss_ms][i], root_partitions[i]))
end
puts "poss_partitions = " + poss_partitions.to_s
