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

# —————— Input file format ——————
# #ofLines
# regions
# #







# INIT FUNCTION
# Normalize root_p
# Enqueue root_p as needing to be expanded (unexpanded_ps)
# Add root_p to Set of unique partitions (unique_ps)
#
# HELPER FUNCTION
# inspect_p(p, unique_ps) -> [valid_ps, unique_ps]
#   If p is unique...
#     Enqueue p in unexpanded_ps
#     Add p to unique_ps
#     If p is valid...
#       Add p to valid_ps
#
#

# HELPER FUNCTION
# expand_p(p, unique_ps) -> [valid_ps, unique_ps]
#   If p is unique...
#     Enqueue p in unexpanded_ps
#     Add p to unique_ps
#     If p is valid...
#       Add p to valid_ps


# Expand p. For each new partition...
#   If it's unique...
#     Enqueue it as needing to be expanded (unexpanded_ps)
#     Add it to Set of unique partitions (unique_ps)
#
#   If it's valid...
#     Add it to Set of valid partitions (valid_ps)
#
#    (This is necessary for validation of future partitions)
