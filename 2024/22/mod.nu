$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input | parse-input
  | par-each {|i| seq 0 1999 | reduce -f $i {|_, acc| $acc | next-secret }}
  | math sum
  | print $'Silver:>($in)'
}

def monkey-up [] {
  let prices = $in
  1..4
  | reduce -f ($prices| wrap 0) {|i, a| $a | drop | merge (
    $a
    | get $'($i - 1)'
    | skip
    | wrap $'($i)'
  )}
  | each {values}
  | each {{
    changes: (
      $in | zip ($in | skip) | each {$in.1 - $in.0}
      | str join
    )
    price: ($in | last)
  }}
  | where price > 0
  | uniq-by changes
  # do { $in | print; $in}
}

def "main gold" [input: path, ] {
  open $input | parse-input
  | enumerate
  | par-each {|i|
    print $i.index
    mut i = $i.item
    mut secrets = []
    for _ in 0..2000 {
      $secrets = $secrets ++ ($i - $i // 10 * 10 )
      $i = $i | next-secret
    }
    $secrets | monkey-up
  }
  | flatten
  | group-by changes
  | values
  | each {get price | math sum}
  | math max
  | print $'Gold:>($in)'
}

# solution for day 2024/5
def main [rest] {
  main gold $rest | print
  return
  main silver $rest
}

def next-secret [] {
  $in * 64 bit-xor $in | $in mod 16777216
  | $in // 32 bit-xor $in
  | $in * 2048 bit-xor $in | $in mod 16777216
}

def parse-input [] {
  lines | into int
}
