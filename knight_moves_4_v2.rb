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
  puts "r_free_cells: " + s[:r_free_cells].to_s
  puts "r_known_cells: " + s[:r_known_cells].to_s
  puts "target_sum: " + s[:target_sum].to_s
  puts "prospective_move: " + s[:prospective_move].to_s
  puts "solved: " + s[:solved].to_s
end

# Open input txt file containing grid info
def read_input_file
  gridfile_name = ARGV[0]
  # puts gridfile_name
  grid_data = File.read(gridfile_name).split
end

def parse_grid_metadata(grid_data)
  x = grid_data[0].strip.to_i
  y = grid_data[1].strip.to_i
  r_start = 2               # r_start - first line of the input file describing the regions
  r_end = r_start + y - 1   # r_end   - last line of the input file describing the regions
  m_start = r_end + 1
  m_end = m_start + y - 1
  # puts "r_start = " + r_start.to_s #NICE TO HAVE
  # puts "r_end = " + r_end.to_s #NICE TO HAVE
  # puts "m_start = " + m_start.to_s #NICE TO HAVE
  # puts "m_end = " + m_end.to_s #NICE TO HAVE
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
  # puts "Parsing region data..."
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
  # puts "num_regions = " + num_regions.to_s
  # puts "r_num_cells = " + r_num_cells.to_s
  # print_board(regions)    #NICE TO HAVE
  region_data = {
    regions: regions,         # 2D array representing regions
    num_regions: num_regions, # number of different regions
    r_num_cells: r_num_cells  # number of cells belonging to region (by index)
  }
end

# Parse moves data from input file based on parsed metadata
def parse_moves_data(gd, gm)
  # puts "Parsing moves data..."
  max_val = 0
  moves = Array.new(gm[:y]) {|e| e = Array.new(gm[:x], -1)}
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
  # puts "max_val = " + max_val.to_s      #NICE TO HAVE
  # print_board(moves)                    #NICE TO HAVE
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
  # puts "ms_per_r = " + ms_per_r.to_s    #NICE TO HAVE
  return ms_per_r
end

# Generate an array of possible total moves that would still allow for a solution
#
# APPARENTLY, this doesn't always work. It can result in false positives. !!!
# m = 11, r = 4 is a counterexample in which the sum per region comes out to 16.5,
#   although this method returns 16 because integers I'm assuming...
def determine_possible_num_moves(gm, rd, md)
  # puts "Determining possible total moves..."    #NICE TO HAVE
  min = [ md[:max_val], rd[:num_regions] * 2 - 1 ].max
  max = gm[:x] * gm[:y]
  poss_ms = []
  for i in min..max do
    if i % rd[:num_regions] == 0 or (i + 1) % rd[:num_regions] == 0
      poss_ms.push(i)
    end
  end
  # puts "poss_ms = " + poss_ms.to_s      #NICE TO HAVE
  return poss_ms
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


# Doing everything from scratch just based on moves, regions, & num_moves.
# Not the most efficient way, but a pretty easy to understand way, so it will
#   serve as a proof of concept for the time being and then be refined later.
#
# moves ---> m
# moves ---> known_moves
# moves ---> unknown_moves
# m + known_moves ---> next_highest_known_m
# m + known_moves + regions ---> r_known_cells
# m + unknown_moves ---> next_highest_unknown_m
# m + unknown_moves + r_num_cells + r_known_cells ---> sum_of_greater_unknown_ms
def derive_moves_metadata(s)
  # puts "Deriving move metadata..." #NICE TO HAVE
  known_moves = Array.new(s[:num_moves]) {|e| e = {x: -1, y: -1}}
  unknown_moves = [*1..s[:num_moves]]
  for y in 0...s[:moves].length do
    row = s[:moves][y]
    for x in 0...row.length do
      if s[:moves][y][x] > 0
        known_moves[s[:moves][y][x]-1] = {x: x, y: y}
        unknown_moves = unknown_moves - [s[:moves][y][x]]
      end
    end
  end
  m = -1
  if not unknown_moves.empty?
    m = unknown_moves[0]
  end
  next_highest_known_m = -1
  for i in m...known_moves.length do
    if known_moves[i][:x] != -1
      next_highest_known_m = i
      break
    end
  end
  next_highest_unknown_m = -1
  unknown_moves.each do |unknown_move|
    if unknown_move > m
      next_highest_unknown_m = unknown_move
      break
    end
  end
  # I'm really bothered by this part, but as stated up top, this is being done
  #   for the sake of simplicity for now, and will be refactored later...
  r_known_cells = Array.new(s[:r_num_cells].length) {|e| e = Array.new()}
  r_free_cells = s[:r_num_cells].clone
  for i in 0...known_moves.length do
    next if known_moves[i][:x] == -1
    r = s[:regions][known_moves[i][:y]][known_moves[i][:x]]
    r_free_cells[r] -= 1
    r_known_cells[r].push(i+1)
  end
  s[:m] = m
  s[:known_moves] = known_moves
  s[:unknown_moves] = unknown_moves
  s[:next_highest_known_m] = next_highest_known_m
  s[:next_highest_unknown_m] = next_highest_unknown_m
  s[:r_known_cells] = r_known_cells
  s[:r_free_cells] = r_free_cells
end

# Find potential first move
def first_moves(s)
  s[:m] = s[:unknown_moves][0]    # Find first unknown move
  poss_moves = get_poss_next_moves(s)
  return poss_moves
end

def validate_state(s)
  # puts "Validating state..." #NICE TO HAVE
  r = s[:prospective_move][:r]
  actual_sum = s[:r_known_cells][r].inject(0, :+)
  difference = s[:target_sum] - actual_sum
  sum_of_greater_unknown_ms = 0
  i = s[:unknown_moves].length-1
  while i >= 0 and i >= s[:unknown_moves].length - s[:r_free_cells][r]
    sum_of_greater_unknown_ms = sum_of_greater_unknown_ms + s[:unknown_moves][i]
    i -= 1
  end
  if difference == 0
    return true
  end
  if difference < s[:next_highest_unknown_m]
    # puts "INVALID STATE -- r " + r.to_s + " is overfilled (target_sum = " + s[:target_sum].to_s + ")" #NICE TO HAVE
    return false # r is overfilled
  end
  if difference > sum_of_greater_unknown_ms
    # puts "INVALID STATE -- r " + r.to_s + " is underfilled (target_sum = " + s[:target_sum].to_s + ")" #NICE TO HAVE
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

# Modifies relevant state variables based on the state's current :prospective_move.
# Returns nothing as it is directly modifiying the state metadata object.
def apply_move(s)
  # puts "\nApplying move..." #NICE TO HAVE
  s[:moves][s[:prospective_move][:y]][s[:prospective_move][:x]] = s[:m]
  derive_moves_metadata(s)
end

# Inverse of the apply_move(s) method defined above.
def undo_move(s)
  # puts "Undoing move..." #NICE TO HAVE
  if s[:m] == -1
    s[:m] = s[:num_moves]
  else
    s[:m] = s[:m] - 1
  end
  while s[:given_moves].include? s[:m] do # Make sure we're not undoing a given move
    s[:m] = s[:m] -1
  end
  xy = s[:known_moves][s[:m]-1]
  s[:moves][xy[:y]][xy[:x]] = 0
  derive_moves_metadata(s)
end

# Returns an array of {:x, :y} objects which represent open positions on the board
#   that are one knight move away from the position of move m.
# If m is not already known, then this function will return an empty array.
def get_adjacent_cells(xi, yi, s)
  adjacent_cells = []
  x_max = s[:moves][0].length
  y_max = s[:moves].length
  KNIGHT_MOVEMENT.each do |move|
    x_new = xi + move[0]
    y_new = yi + move[1]
    if (x_new >= 0) && (x_new < x_max) && (y_new >= 0) && (y_new < y_max) # Cell is in bounds
      if s[:moves][y_new][x_new] == 0                                     # Cell is available
        adjacent_cells.push({x: x_new, y: y_new})
      end
    end
  end
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
def recursive_function(solutions, s)
  # puts "BEGINNING RECURSIVE FUNCTION" #NICE TO HAVE
  # print_board s[:moves] #NICE TO HAVE
  if not validate_state(s)
    return s
  end
  if check_solved(s)
    s[:solved] = true
    # puts "A solution has been found."   #NICE TO HAVE
    # print_state_data(s) #NICE TO HAVE
    solutions.push(deep_copy_solution(s[:moves]))
    return solutions
  end
  derive_moves_metadata(s)
  poss_moves = get_poss_next_moves(s)
  while not poss_moves.empty?
    # puts "poss_moves: " + poss_moves.to_s #NICE TO HAVE
    s[:prospective_move] = poss_moves.shift()
    s[:prospective_move][:r] = s[:regions][s[:prospective_move][:y]][s[:prospective_move][:x]]
    apply_move(s)
    recursive_function(solutions, s)
    undo_move(s)
    # print_board s[:moves] #NICE TO HAVE
  end
  return s
end

def deep_copy_solution(moves)
  solution = []
  moves.each do |row|
    solution.push(row.clone)
  end
  return solution
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
# print_state_data(state_data)    #NICE TO HAVE
solutions = []
moves_data[:poss_ms].each do |poss_max_m|
  state_data[:num_moves] = poss_max_m
  # puts "\n\n————————————————————"               #NICE TO HAVE
  # puts " New poss_max_m = " + poss_max_m.to_s   #NICE TO HAVE
  # puts "————————————————————"                   #NICE TO HAVE
  state_data[:target_sum] = tri(state_data[:num_moves]) / state_data[:r_num_cells].length
  derive_moves_metadata(state_data)
  recursive_function(solutions, state_data)
end
puts "\n ------ SOLUTIONS ------"
i = 1
solutions.each do |solution|
  puts "\nPossible solution " + i.to_s + ":"
  print_board(solution)
  i += 1
end
if i == 1
  puts "\nNo possible solutions were found."
  puts
end
