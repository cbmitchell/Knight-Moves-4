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
    for j in 0...gm[:x] do
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

# Returns an array of length |rr| (the number of distinct regions).
# Each entry in the array is another array containing integers which represent
#   known values belonging to the region associated with the array's index.
def construct_ms_per_r(gm, rd, md)
  ms_per_r = Array.new(rd[:num_regions]) {|e| e = Array.new}
  for y in 0...gm[:y] do
    for x in 0...gm[:x] do
      if md[:moves][y][x] != 0
        r = rd[:regions][y][x]
        ms_per_r[r].push(md[:moves][y][x])
      end
    end
  end
  puts "ms_per_r = " + ms_per_r.to_s
  return ms_per_r
end

# Generate an array of possible total moves that would still allow for a solution
#
# APPARENTLY, this doesn't always work. It can result in false positives. !!!
# m = 11, r = 4 is a counterexample in which the sum per region comes out to 16.5,
#   although this method returns 16 because integers I'm assuming...
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

# Return a possible partitioning of m sequential values among r regions such
#   that the sum of all values in a region is equivalent to the sum of all
#   values in any other region.
# Should be noted that the method used below only works because we know we're
#   dealing with a complete triangular number sequence up to m.
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

# ???????????? PSEUDOCODE ????????????
# Q.push(root_p)
# while !Q.empty? {
#   p = Q.shift()
#   if unique(p) {
#     U.push(p)
#     N = get_neighbors(p)
#     for n in N {
#       Q.push(n)
#     }
#     if valid(p) {
#       V.push(p)
#     }
#   }
# }
#
# It should be noted that this function only calculates all possible partitions
#   of the same length as the provided root_partition.
#
# Well, I just tried running this on a 5x5 example, and it took WAY too long.
# As a matter of fact, I got impatient and stopped it before it finished.
# Anyway, my point is that we need to figure out a way to decrease the time
#   complexity on this beast or we're boned. As it currently is, the thing just
#   takes FAR too long to run...
# So it would stand to reason that I can decrease the complexity of this thing
#   by introducing more insight I have about the nature of the problem and its solutions.
#   This includes the following:
#     -
def calc_all_poss_partitions(root_partition, rd, md)
  # puts "\nCalculating all possible partitions of length " + root_partition.length.to_s
  root_p = normalize_partition(root_partition)
  unvisited_ps = [root_p]
  unique_ps = []
  valid_ps = []
  while not unvisited_ps.empty? do
    p = unvisited_ps.shift
    # puts "Visiting partition  " + p.to_s + "... "
    if not unique_ps.include?(p)
      unique_ps.push(p)
      # puts p.to_s + " is unique - Now expanding... "
      # NOTE: It might be a bit cleaner to have a function that gets all
      #   neighboring partitions, and then have that be SEPARATE from
      #   the function that validates them. Still, this would result in
      #   an absolutely massive neighboring_ps for larger examples, and
      #   that would be bad in terms of space and time...
      neighboring_ps = calc_poss_partitions(p, rd, md)
      neighboring_ps.each do |n|
        unvisited_ps.push(n)
      end
      if validate_partition(p, rd, md)
        valid_ps.push(p)
      end
    end
  end
  # puts "calc_all_poss_partitions resulted in " + valid_ps.length.to_s + " partitions."
  return valid_ps
end

# Returns an array of arrays, where each array represents a unique, valid
#   partition given r & m.
# This array of partitions is not comprehensive. All the partitions in the array
#   are only one step removed from the provided root_partition, where a "step"
#   is defined as a swapping of summands between only two regions such that the
#   regions retain their original sums.
# Could definitely be optimized. Currently, it is quite inefficient...
# I should also mention that this thing has really really terrible big O.
#   I mean, if this gets up to even 25 possible moves, it produces a downright
#   absurd number of possible partitions.
# This function essentially EXPANDS A NODE where each node is a unique partition.
# To the above point, this function is used to create a tree of nodes from inside
#   the calc_all_poss_partitions(...) method above.
def calc_poss_partitions(root_partition, rd, md)
  root_partition = normalize_partition(root_partition)
  # puts "root_partition    = " + root_partition.to_s
  r = rd[:r_num_cells].length
  poss_partitions = Array.new
  # poss_partitions.push(root_partition)
  xxs = create_r_arrays_from_partition(rd[:r_num_cells], root_partition)

  i_j_combinations = (0...xxs.length).to_a.combination(2).to_a
  i_j_combinations.each do |ij|
    xx_i_combinations = (1...xxs[ij[0]].length).flat_map{|size| xxs[ij[0]].combination(size).to_a}
    xx_j_combinations = (1...xxs[ij[1]].length).flat_map{|size| xxs[ij[1]].combination(size).to_a}
    xx_i_combinations.each do |xx_i_combination|
      xx_i_sum = xx_i_combination.inject(0, :+)
      xx_j_combinations.each do |xx_j_combination|
        xx_j_sum = xx_j_combination.inject(0, :+)
        # This part is horribly inefficient. I already know some ways
        #   it could be improved, but I just want a proof of concept for
        #   the time being, so maybe I'll come back and optimize later.
        if xx_i_sum == xx_j_sum
          new_partition = create_new_partition(root_partition, xx_i_combination, xx_j_combination)
          new_partition = normalize_partition(new_partition)
          # Originally, I had this part cut down the number of partitions it returned by
          #   making it only return VALID partitions. Now that I'm essentially using this
          #   as a method of EXPANDING from a given partition, I should allow it to return
          #   invalid partitions, as they could still have valid children which would not
          #   be reachable otherwise.
          # if (not poss_partitions.include? new_partition) and validate_partition(new_partition, rd, md)
          if not poss_partitions.include? new_partition
            poss_partitions.push(new_partition)
            # puts "poss_partition[" + (poss_partitions.length-1).to_s + "] = " + new_partition.to_s
          end
        end
      end
    end
  end
  return poss_partitions
end

# - Create r arrays,
#   Each array will represent one region of the root_partition.
#   These arrays will contain integers representing the values in that region that
#   contribute to the region's sum.
def create_r_arrays_from_partition(r_num_cells, root_partition)
  xxs = Array.new(r_num_cells.length) {|e| e = Array.new}
  for i in 1..root_partition.length
    xxs[root_partition[i-1]].push(i)
  end
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

# Validate partition based on the following:
#   1. r_num_cells
#   2. moves (known cell values and their associated regions)
def validate_partition(partition, rd, md)

  # Validate based on region data
  r_num_cells_sorted = rd[:r_num_cells].sort
  p_num_cells = Array.new(rd[:r_num_cells].length, 0)
  for i in 0...partition.length do
    p_num_cells[partition[i]] += 1
  end
  p_num_cells_sorted = p_num_cells.sort
  for i in 0...p_num_cells_sorted.length do
    if r_num_cells_sorted[i] < p_num_cells_sorted[i]
      return false
    end
  end

  # Validate based on moves data
  xxs = create_r_arrays_from_partition(rd[:r_num_cells], partition)
  ms_per_r = rd[:ms_per_r]
  for r in 0...ms_per_r.length do
    next if ms_per_r[r].empty?
    max_size = rd[:r_num_cells][r]
    for i in 0...ms_per_r[r].length do
      partition_r_containing_m = partition[ms_per_r[r][i]-1]
      actual_size = xxs[partition_r_containing_m].length
      if actual_size > max_size
        return false
      end
    end
  end
  return true
end

# Validates whether or not a proposed partition conforms to the r_num_cells
# Returns true if valid, false otherwise.
def validate_partition_regions(partition, r_num_cells)
  r_num_cells_sorted = r_num_cells.sort
  p_num_cells = Array.new(r_num_cells.length, 0)
  for i in 0...partition.length do
    p_num_cells[partition[i]] += 1
  end
  p_num_cells_sorted = p_num_cells.sort
  for i in 0...p_num_cells_sorted.length do
    if r_num_cells_sorted[i] < p_num_cells_sorted[i]
      return false
    end
  end
  return true
end

# ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

grid_data = read_input_file
grid_metadata = parse_grid_metadata(grid_data)
region_data = parse_region_data(grid_data, grid_metadata)
moves_data = parse_moves_data(grid_data, grid_metadata)
region_data[:ms_per_r] = construct_ms_per_r(grid_metadata, region_data, moves_data)
moves_data[:poss_ms] = determine_possible_num_moves(grid_metadata, region_data, moves_data)

root_partitions = []
moves_data[:poss_ms].each do |m|
  root_partition = calc_root_partition(region_data[:num_regions], m)
  puts "Root partition for " + m.to_s + " moves: " + root_partition.to_s
  root_partitions.push(root_partition)
end

all_poss_partitions = []
for i in 0...root_partitions.length do
  all_poss_partitions.push(calc_all_poss_partitions(root_partitions[i], region_data, moves_data))
end
puts "\nall_poss_partitions = "
all_poss_partitions.each do |m_poss_partitions|
  print_board(m_poss_partitions)
end
