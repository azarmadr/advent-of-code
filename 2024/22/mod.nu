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
  let a = 0..2
  | reduce -f [$prices] {|i, a| $a | append [($a | last | skip)]}
  $a.0 | zip $a.1 | zip $a.2 | zip $a.3 | each {flatten | flatten}
}

def "main gold" [input: path, ] {
  open $input | parse-input
  | each {|i|
    seq 0 19
    | reduce -f [$i] {|_, acc| $acc | append ($acc | last | next-secret)}
    | each {$in - $in // 10 * 10}
    | monkey-up
  }
  | $in.0 | table -e
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
