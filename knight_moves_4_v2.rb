#!/usr/bin/ruby

KNIGHT_MOVEMENT = [
  [1, -2], [2, -1], [2, 1], [1, 2], [-1, 2], [-2, 1], [-2, -1], [-1, -2]
]

# Print out the board
def print_board(board)
  board.each do |row|
    puts row.to_s
  end
end

def print_state_data(s)
  puts "m: " + s[:m].to_s
  # puts "r: " + s[:r].to_s
  puts "moves: "
  print_board(s[:moves]).to_s
  puts "num_moves: " + s[:num_moves].to_s
  puts "known_moves: " + s[:known_moves].to_s
  puts "given_moves: " + s[:given_moves].to_s
  puts "unknown_moves: " + s[:unknown_moves].to_s
  puts "next_highest_known_m: " + s[:next_highest_known_m].to_s
  puts "next_highest_unknown_m: " + s[:next_highest_unknown_m].to_s
  puts "regions: "
  print_board(s[:regions])
  puts "r_num_cells: " + s[:r_num_cells].to_s
  puts "r_known_cells: " + s[:r_known_cells].to_s
  puts "target_sum: " + s[:target_sum].to_s
  puts "sum_of_greater_unknown_ms: " + s[:sum_of_greater_unknown_ms].to_s
  puts "prospective_move: " + s[:prospective_move].to_s
  puts "solved: " + s[:solved].to_s
end

# Open input txt file containing grid info
def read_input_file
  gridfile_name = ARGV[0]
  puts gridfile_name
  grid_data = File.read(gridfile_name).split
end

def parse_grid_metadata(grid_data)
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
  # In theory, I should be doing this known_moves thing in a later function
  #   since it's technically derived. But for now this is simpler. I can try
  #   refactoring that later when I'm not trying to balance a ton of things in
  #   my head all at once...
  known_moves = Array.new(gm[:x] * gm[:y]) {|e| e = {x: -1, y: -1}}
  given_moves = []
  for i in gm[:m_start]..gm[:m_end] do
    cells = gd[i].strip.split(',')
    for j in 0...gm[:x] do
      moves[i-1-gm[:r_end]][j] = cells[j].to_i
      if cells[j].to_i > 0
        known_moves[cells[j].to_i-1] = {x: j, y: i-1-gm[:r_end]}
        given_moves.push(cells[j].to_i)
      end
      if cells[j].to_i > max_val
        max_val = cells[j].to_i
      end
    end
  end
  unknown_moves = [*1..(gm[:x] * gm[:y])] - given_moves
  puts "max_val = " + max_val.to_s
  print_board(moves)
  puts
  moves_data = {
    moves: moves,     # 2D array representing positions of known cell values
    max_val: max_val, # highest known cell value provided in the input file
    known_moves: known_moves,
    given_moves: given_moves,
    unknown_moves: unknown_moves
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

# Calculate triangular number
def tri(m)
  tri_m = (m * (m + 1)) / 2
end

# ———————————————————— # ———————————————————— # ————————————————————
# ———————————————————— # ———— PSEUDOCODE ———— # ————————————————————
# ———————————————————— # ———————————————————— # ————————————————————
# state = {
#   m: ,
#     - An integer representing the current move number
#
#   moves: ,
#     - A 2D array of integers representing known moves on the board
#
#   num_moves: ,
#     - An integer representing the max value for m
#     - Based on poss_ms from elsewhere in this file
#
#   given_moves: ,
#     - An integer array containing all the moves known from the input file.
#     - Used to avoid undoing a given move when using undo_move.
#     - Not derived, and does not change over the course of the program.
#
#   known_moves: ,
#     - An array in which each element is a two-key object of the form, {:x, :y}.
#     - Each element is initialized to {x: -1, y: -1}
#     - An element is assigned another value when the move associated with that
#       element's index becomes known.
#
#   unknown_moves: ,
#     - An array of integers, where each integer represents an unknown move
#     - Initialized to have all moves
#     - The integers are listed in descending order, starting with num_moves
#
#   next_highest_known_m: ,
#     -
#
#   next_highest_unknown_m: ,
#     -
#
#   prospective_move: ,
#     - The x & y coordinates that m will be placed in
#     - Also the r
#
#   regions: ,
#     - Same as the original regions metadata
#     - Never changes
#
#   r_num_cells: ,
#     - An array of integers where each integer represents the total number of
#       cells available in the region associated with the integer's index.
#
#   r_known_cells: ,
#     - A 2D array where each element is an array containing integers representing
#       moves known to be made in the region associated with the array's index.
#
#   target_sum: ,
#     - The value that all regions should ultimately total to
#
#   sum_of_greater_unknown_ms: ,
#     - Derived from m & unknown_moves
#
#   solved: false,
#     - A boolean representing whether or not the state is considered solved
# }
# ———————————————————— # ———————————————————— # ————————————————————
#
# recursive_function(current_state) {
#   if not validate(current_state) {
#     return current_state
#   }
#   if check_solved(current_state) {
#     current_state[:solved] = true
#     return current_state
#   }
#   poss_moves = get_poss_moves(...)
#   while not poss_moves.empty? {
#     prospective_move = poss_moves.shift()
#     next_state = recursive_function(prospective_move)
#     if next_state[:solved] {
#       return next_state
#     }
#   }
#   return current_state
# }
#
# ———————————————————— # ———————————————————— # ————————————————————
# ———————————————————— # ———————————————————— # ————————————————————
# ———————————————————— # ———————————————————— # ————————————————————

# Find potential first move
def first_moves(s)
  # m = s[:unknown_moves][0]     # Find first unknown move
  s[:m] = s[:unknown_moves][0]
  poss_moves = get_poss_next_moves(s)
  return poss_moves
end


def validate_state(s)
  puts "Validating state..."
  # Pretty sure the way I'm currently doing this, I'm not applying the prospective_move
  #   before validation the first time around, so this might not be good... !!!***
  r_known_cells = s[:r_known_cells][s[:prospective_move][:r]]
  r_num_cells = s[:r_num_cells][s[:prospective_move][:r]]
  actual_sum = r_known_cells.inject(0, :+)
  difference = s[:target_sum] - actual_sum
  if difference < s[:next_highest_unknown_m]
    puts "INVALID STATE -- r " + s[:prospective_move][:r].to_s + " is overfilled (target_sum = " + s[:target_sum].to_s + ")"
    return false # r is overfilled
  end
  if difference > s[:sum_of_greater_unknown_ms]
    puts "INVALID STATE -- r " + s[:prospective_move][:r].to_s + " is underfilled (target_sum = " + s[:target_sum].to_s + ")"
    return false # r is underfilled
  end
  return true
end

def check_solved(s)
  target_sum = tri(s[:num_moves]) / s[:r_num_cells].length
  if not s[:unknown_moves].empty?
    return false
  end
  s[:r_known_cells].each do |r_cells|
    r_sum = 0
    r_cells.each do |r_cell|
      r_sum += r_cell
    end
    if r_sum != target_sum
      return false
    end
  end
  return true
end

def derive_state_metadata(s)
  r = s[:regions][s[:prospective_move][:y]][s[:prospective_move][:x]]
  target_sum = tri(s[:num_moves]) / s[:r_num_cells].length
  next_highest_known_m = 0
  for i in s[:m]...s[:known_moves].length do
    if s[:known_moves][i][:x] != -1
      # TODO: this part is throwing out really high values for some reason.
      next_highest_known_m = i + 1
      break
    end
  end
  next_highest_unknown_m = 0
  i = s[:unknown_moves].length - 1
  while i >= 0
    if s[:unknown_moves][i] > s[:m]
      next_highest_known_m = s[:unknown_moves][i]
      break
    end
    i -= 1
  end
  sum_of_greater_unknown_ms = 0
  for i in 0...( s[:r_num_cells][r] - s[:known_moves][r].length ) do #this range operator might break !!!***
    sum_of_greater_unknown_ms += s[:unknown_moves][i] # Pretty sure this will never go out of bounds...
  end
  s[:prospective_move][:r] = r
  s[:target_sum] = target_sum
  s[:next_highest_known_m] = next_highest_known_m
  s[:next_highest_unknown_m] = next_highest_unknown_m
  s[:sum_of_greater_unknown_ms] = sum_of_greater_unknown_ms
end

# Separate note from the above:
# I may also consider splitting up my state metadata object into two different objects:
#   * state_data
#     * Contains the minimum set of data required to derive everything else.
#   * state_metadata
#     * Contains all the values derived from values contained in state_data.

# Modifies relevant state variables based on the state's current :prospective_move.
# Returns nothing as it is directly modifiying the state metadata object.
def apply_move(s) #TODO -- DOUBLE-CHECK THE LOGIC FOR THIS FUNCTION!!!***
  puts "\nApplying move..."
  derive_state_metadata(s)
  print_state_data(s)
  s[:moves][s[:prospective_move][:y]][s[:prospective_move][:x]] = s[:m]
  s[:r_known_cells][s[:prospective_move][:r]].push(s[:m])
  s[:known_moves][s[:m]][:x] = s[:prospective_move][:x]
  s[:known_moves][s[:m]][:y] = s[:prospective_move][:y]
  s[:unknown_moves] = s[:unknown_moves] - [s[:m]]
  s[:m] = s[:m] + 1 # Not ENTIRELY sure about this, but we'll see how it goes...
  derive_state_metadata(s)
end

# Modifies relevant state variables based on the state's current :prospective_move.
# Returns nothing as it is directly modifiying the state metadata object.
# def apply_move(s) #TODO -- DOUBLE-CHECK THE LOGIC FOR THIS FUNCTION!!!***
#   puts "\nApplying move..."
#   s[:moves][s[:prospective_move][:y]][s[:prospective_move][:x]] = s[:m]
#   s[:m] = s[:m] + 1 # Not ENTIRELY sure about this, but we'll see how it goes...
#   # print_state_data(s)
#   derive_state_metadata(s)
# end

# Inverse of the apply_move(s) method defined above.
# We'll need to make sure that this function doesn't undo any
#   given moves. This will require a new state variable, given_moves.
def undo_move(s) #TODO -- DOUBLE-CHECK THE LOGIC FOR THIS FUNCTION!!!***
  puts "\nUndoing move..."
  s[:m] = s[:m] - 1
  while s[:given_moves].include? s[:m] do # Make sure we're not undoing a given move
    s[:m] = s[:m] -1
  end
  xy = s[:known_moves][s[:m]-1]
  s[:known_moves][s[:m]-1] = {x: -1, y: -1}
  r = s[:regions][xy[:y]][xy[:x]]
  s[:moves][xy[:y]][xy[:x]] = 0
  puts "     r = " + r.to_s
  s[:r_known_cells][r].pop()
  s[:unknown_moves] = s[:unknown_moves].push(s[:m]).sort.reverse()
  derive_state_metadata(s)
end

# Well, everything else is theoretically in place. Now I just need to
#   program a solution to the regular version of the Knight's Tour.
# How hard could that possibly be...?
# Anyway...

# Returns an array of {:x, :y} objects which represent open positions on the board
#   that are one knight move away from the position of move m.
# If m is not already known, then this function will return an empty array.
def get_adjacent_cells(xi, yi, s)
  # puts "xi = " + xi.to_s + "      yi = " + yi.to_s
  adjacent_cells = []
  x_max = s[:moves][0].length
  y_max = s[:moves].length
  KNIGHT_MOVEMENT.each do |move|
    x_new = xi + move[0]
    y_new = yi + move[1]
    if (x_new >= 0) && (x_new < x_max) && (y_new >= 0) && (y_new < y_max) # Cell is in bounds
      # puts "x_new = " + x_new.to_s + "     y_new = " + y_new.to_s
      if s[:moves][y_new][x_new] == 0                                       # Cell is available
        adjacent_cells.push({x: x_new, y: y_new})
      end
    end
  end
  # puts "adjacent_cells: " + adjacent_cells.to_s
  return adjacent_cells
end

# Returns an array of {:x, :y} objects which represent possible knight moves from the
#   position specified by the :prospective_move object contained in the state metadata
def get_poss_moves_from_prev(s)
  if s[:m] != 1
    return get_adjacent_cells(s[:known_moves][s[:m]-2][:x], s[:known_moves][s[:m]-2][:y], s)
  else
    return []
  end
end

def get_poss_moves_from_next(s)
  hi_m = s[:next_highest_known_m]
  if hi_m == 0
    return []
  end
  move_queue_1 = []
  move_queue_2 = []
  i = 0
  move_queue_1.push(s[:known_moves][hi_m-1])
  while i < hi_m - s[:m]
    while not move_queue_1.empty?
      curr_move = move_queue_1.shift()
      new_moves = get_adjacent_cells(curr_move[:x], curr_move[:y], s)
      new_moves.each do |new_move|
        if not move_queue_2.include? new_move
          move_queue_2.push(new_move)
        end
      end
    end
    move_queue_1.concat(move_queue_2)
    move_queue_2.clear
    i += 1
  end
  return move_queue_1
end

def get_poss_next_moves(s)
  next_highest_known_m = 0
  for i in s[:m]...s[:known_moves].length do
    # puts "i = " + i.to_s
    # puts s[:known_moves][i]
    if s[:known_moves][i][:x] != -1
      next_highest_known_m = i + 1
      break
    end
  end
  s[:next_highest_known_m] = next_highest_known_m
  poss_moves = []
  if s[:known_moves][s[:m]-1][:x] != -1     # If the current move is already known...
    poss_moves = [s[:known_moves][s[:m]-1]] # ...only possible next move is that move.
  else
    next_lowest_known_m = s[:m] - 1
    poss_moves_from_prev = get_poss_moves_from_prev(s)
    poss_moves_from_next = get_poss_moves_from_next(s)
    # puts "poss_moves_from_prev: " + poss_moves_from_prev.to_s
    # puts "poss_moves_from_next: " + poss_moves_from_next.to_s
    if not poss_moves_from_next.empty?
      if not poss_moves_from_prev.empty?
        poss_moves = poss_moves_from_prev & poss_moves_from_next
      else
        poss_moves = poss_moves_from_next
      end
    else
      poss_moves = poss_moves_from_prev
    end
  end
  return poss_moves
end

# Recursive function that ultimately returns a solved version of the state.
# TODO: Needs to be renamed.
def recursive_function(s)
  puts "BEGINNING RECURSIVE FUNCTION"
  print_board s[:moves]
  if not validate_state(s)
    return s
  end
  if check_solved(s)
    s[:solved] = true
    puts "A solution has been found."
    return s
  end
  derive_state_metadata(s) # CHRIS -- Not so sure about this...
  # # TODO:  Have logic to initially insert a prospective move or have the
  #          derive_state_metadata function not rely on it.
  # print_state_data(s)
  # ------ get_poss_next_moves ------
  poss_moves = get_poss_next_moves(s)
  # if s[:known_moves][s[:m]-1][:x] != -1     # If the current move is already known...
  #   poss_moves = [s[:known_moves][s[:m]-1]] # ...only possible next move is that move.
  # else
  #   next_lowest_known_m = s[:m] - 1
  #   poss_moves_from_prev = get_poss_moves_from_prev(s)
  #   poss_moves_from_next = get_poss_moves_from_next(s)
  #   if not poss_moves_from_next.empty?
  #     if not poss_moves_from_prev.empty?
  #       poss_moves = poss_moves_from_prev & poss_moves_from_next
  #     else
  #       poss_moves = poss_moves_from_next
  #     end
  #   else
  #     poss_moves = poss_moves_from_prev
  #   end
  # end
  while not poss_moves.empty?
    puts "poss_moves: " + poss_moves.to_s
    s[:prospective_move] = poss_moves.shift()
    s[:prospective_move][:r] = s[:regions][s[:prospective_move][:y]][s[:prospective_move][:x]]
    apply_move(s)
    next_state = recursive_function(s)
    if next_state[:solved]
      return next_state
    end
    undo_move(s)
  end
  return s
end

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

def initialize_state_data(rd, md)
  state = {
    m: 1,
    moves: md[:moves],
    known_moves: md[:known_moves],
    given_moves: md[:given_moves],
    unknown_moves: md[:unknown_moves],
    poss_num_moves: md[:poss_ms],
    r: rd[:num_regions],
    regions: rd[:regions],
    r_num_cells: rd[:r_num_cells],
    r_known_cells: rd[:ms_per_r],
    prospective_move: {
      x: -1,
      y: -1,
      r: -1
    },
    solved: false
  }
end

# ——————————————————————————————————————————————————————————————————————————————

grid_data = read_input_file
grid_metadata = parse_grid_metadata(grid_data)
region_data = parse_region_data(grid_data, grid_metadata)
moves_data = parse_moves_data(grid_data, grid_metadata)
region_data[:ms_per_r] = construct_ms_per_r(grid_metadata, region_data, moves_data)
moves_data[:poss_ms] = determine_possible_num_moves(grid_metadata, region_data, moves_data)
state_data = initialize_state_data(region_data, moves_data)
print_state_data(state_data)
poss_moves = first_moves(state_data)
puts "\nposs_moves: " + poss_moves.to_s
moves_data[:poss_ms].each do |poss_max_m|
  state_data[:num_moves] = poss_max_m
  puts "\n\nNew poss_max_m = " + poss_max_m.to_s
  poss_moves.each do |poss_move|
    state_data[:prospective_move][:x] = poss_move[:x]
    state_data[:prospective_move][:y] = poss_move[:y]
    # print_state_data(state_data)
    # puts "\nderiving state metadata..."
    derive_state_metadata(state_data)
    # print_state_data(state_data)
    recursive_function(state_data)
  end
end


# puts "Printing initial state data:"
# print_state_data(state_data)
# derive_state_metadata(state_data)
# puts "Printing newly-derived state data:"
# print_state_data(state_data)
