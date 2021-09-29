#!/usr/bin/ruby

# Okay, so I'm making this in order to solve the Knight Moves 4 puzzle for Jane Street.
# The puzzle can be found here: https://www.janestreet.com/puzzles/current-puzzle/
# It doesn't really SAY to solve it with code, but solving it by hand seems... very complicated.
# I mean, I think I'd be able to solve it eventually, but I wasn't satisfied with the
#   pace of my progress on it, so here we are.
# At the very least, this'll give me a chance to practice my ruby scripting.

# Anyway, I'll need to start by deciding how to program this thing.

# First, I'll need to figure out a format for representing the discrete regions.
# It would be nice if I could pass in a file that does that.
# In theory, I only need to program in the one case, but having it be flexible
#   would make testing this much, much easier.
# Variables:
#   - height of grid
#   - width of grid
#   - boundaries of regions
#   - correct values of each cell
#   - number of distinct regions ??
#     - This one is sortof implied by the boundaries one, but whatever.
