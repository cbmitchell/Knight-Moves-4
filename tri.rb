#!/usr/bin/ruby

m = ARGV[0].to_i
r = ARGV[1]
tri_m = (m * (m + 1)) / 2
if r.nil?
  puts "tri(" + m.to_s + ") = " + tri_m.to_s
else
  sum_m_r = tri_m / r.to_i
  puts "region_sum(" + m.to_s + ", " + r + ") = " + sum_m_r.to_s
end
