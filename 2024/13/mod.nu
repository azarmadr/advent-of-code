$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def calculate-tokens [--less-than-100 (-l)] {
  insert a {($in.by * $in.px - $in.bx * $in.py) / $in.det}
  | insert b {($in.ax * $in.py - $in.ay * $in.px) / $in.det}
  | filter {$in.a == ($in.a | into int) and $in.b == ($in.b | into int)}
  | filter {not $less_than_100 or $in.a <= 100 and $in.b <= 100}
  | each {$in.a * 3 + $in.b}
  | math sum
}

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input | parse-input
  | calculate-tokens -l
}

def "main gold" [input: path, ] {
  open $input | parse-input
  | update px {$in + 10000000000000}
  | update py {$in + 10000000000000}
  | calculate-tokens
}

# solution for day 2024/5
def main [rest] {
  debug profile -l -m 3 {
    main gold $rest | print $'Gold:> ($in)'
    main silver $rest | print $'Silver:> ($in)'
  }
  | move duration_ms --after line
  | sort-by duration_ms
  | reject file
  | print
}

def parse-input [] {
  str replace -ar '(\d)\n' '$1-'
  | lines
  | parse 'Button A: X+{ax}, Y+{ay}-Button B: X+{bx}, Y+{by}-Prize: X={px}, Y={py}-'
  | move ay --after bx
  | move px --before ay
  | update cells {into int}
  | insert det {$in.ax * $in.by - $in.ay * $in.bx}
  | where det != 0
}
