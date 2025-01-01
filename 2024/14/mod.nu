$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input | parse-input
}

def "main gold" [input: path, ] {
  open $input | parse-input
  | update p {|r|
    [
    ($r.p.0 + 100 * $r.v.0 | $in mod 101)
    ($r.p.1 + 100 * $r.v.1 | $in mod 103)
    ]
  }
  | filter { $in.p.0 != 50 and $in.p.1 != 51 }
  | uniq-by p -c
  | flatten
  | group-by --to-table {match $in.p {
    [$a $b] if $a < 50 and $b < 51 => 1
    [$a $b] if $a > 50 and $b < 51 => 2
    [$a $b] if $a < 50 and $b > 51 => 3
    [$a $b] if $a > 50 and $b > 51 => 4
    _ => 0
  }} | do {$in | flatten | flatten | inspect; $in}
  | get items
  | each {get count | math sum}
  | math product
}

# solution for day 2024/5
def main [rest] {
  main silver $rest | print $'Silver:> ($in)'
  main gold $rest | print $'Gold:> ($in)'
}

def parse-input [] {
parse 'p={p} v={v}'
| update cells {split row , | into int}
}
