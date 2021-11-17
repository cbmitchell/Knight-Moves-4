ALRIGHT, there's a new plan.
So at this point, I need to ask myself what I actually plan on doing now.
The reason I decided to do this programatically in the first place was becasue
 I was getting the feeling that at some point, this puzzle would require some
 amount of brute force in order to solve.
I mean, it might be possible to completely logic this thing out by hand without
 needing to brute force anything, but I got the disticnt impression that IF it
 was indeed possible, it would take me a lot of effort to figure out.
So hey, why not play to my strengths? I know how to code things, and computers
 are exceptionally good at brute-forcing things like this.
But I digress. At this point, there is one looming question:
     What can I have the program figure out for me?

Answer: I'm going to have it calculate all the possible ways to partition the
        values in the triangular sequence that meet the following criteria:
  1. The sums of all partitions are equal.
  2. The number of partitions is equal to the number of regions.
  3. Each partition corresponds to a different region in terms of the number
     of cells contained in the region.
Here's what I plan on doing:
Given a set, R, which has the following qualities:
  1. |R| = # distinct regions
  2. Each element in R is an integer that represents the number of cells
     contained within a given region (the regions will be identified by their
     index in the array).
(I actually have a variable for this already, (region_data[:r_num_cells]) )

Okay, so next question: How the do I actually make a method that does this?
Well, to answer that question, I should probably think about the axioms I know
  of, and the observations that I can derive from them.
...or maybe I could just go for it...


Below is a comment I originally had in knight_moves_4_v2.rb. It's really large,
so I opted to remove it


## state structure
- `m`
  - An integer representing the current move number

- `moves`
  - A 2D array of integers representing known moves on the board

- `num_moves`
  - An integer representing the max value for m
  - Based on poss_ms from elsewhere in this file

- `given_moves`
  - An integer array containing all the moves known from the input file.
  - Used to avoid undoing a given move when using undo_move.
  - Not derived, and does not change over the course of the program.

- `known_moves`
  - An array in which each element is a two-key object of the form, {:x, :y}.
  - Each element is initialized to {x: -1, y: -1}
  - An element is assigned another value when the move associated with that
    element's index becomes known.

- `unknown_moves`
  - An array of integers, where each integer represents an unknown move
  - Initialized to have all moves
  - The integers are listed in descending order, starting with num_moves

- `next_highest_known_m`
  -

- `next_highest_unknown_m`
  -

- `prospective_move`
  - The x & y coordinates that m will be placed in
  - Also the r

- `regions`
  - Same as the original regions metadata
  - Never changes

- `r_num_cells`
  - An array of integers where each integer represents the total number of
    cells available in the region associated with the integer's index.

- `r_known_cells`
  - A 2D array where each element is an array containing integers representing
    moves known to be made in the region associated with the array's index.

- `target_sum`
  - The value that all regions should ultimately total to

- `sum_of_greater_unknown_ms`
  - Derived from m & unknown_moves

- `solved`: false,
  - A boolean representing whether or not the state is considered solved
---
```
recursive_function(current_state) {
  if not validate(current_state) {
    return current_state
  }
  if check_solved(current_state) {
    current_state[:solved] = true
    return current_state
  }
  poss_moves = get_poss_moves(...)
  while not poss_moves.empty? {
    prospective_move = poss_moves.shift()
    next_state = recursive_function(prospective_move)
    if next_state[:solved] {
      return next_state
    }
  }
  return current_state
}
```
