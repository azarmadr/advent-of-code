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

def merge-price-groups [new] {
  [$in $new]
  | flatten
  | reduce -f {} {|i a| $a | upsert $i.changes {($in | default 0) + $i.price}}
  | transpose changes price
}

def "main gold" [input: path, ] {
  open $input | parse-input
  | enumerate
  | par-each {|i|
    print $i.index
    let i = $i.item
    seq 0 1999
    | reduce -f [$i] {|_, acc| $acc | append ($acc | last | next-secret)}
    | each {$in - $in // 10 * 10}
    | monkey-up
  }
  | reduce -f [] {|i a|
    $i | merge-price-groups $a
  }
  | get price
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
