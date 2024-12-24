$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def get-value [-b, reg] {
  transpose k v
  | where k starts-with $reg
  | update k {str replace $reg '' | into int}
  | sort-by k -r
  | get v
  | str join
  | if $b {$in} else {into int -r 2}
}

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  let system = open $input | parse-input
  mut gates = $system.1
  mut reg = $system.0
  loop {
    let h = $gates | first
    let r = $reg
    $gates = $gates | skip
    if ($h.in | all {$in in $r}) {
      $reg = $reg | insert $h.out (match $h.op {
        AND => ($h.in | each {|i| $r | get $i} | $in.0 bit-and $in.1)
        OR  => ($h.in | each {|i| $r | get $i} | $in.0 bit-or  $in.1)
        XOR => ($h.in | each {|i| $r | get $i} | $in.0 bit-xor $in.1)
      })
    } else {
      $gates = $gates ++ $h
    }
    if ($gates | is-empty) { break }
  }
  $reg | get-value z
}

def "main gold" [input: path, ] {
  let system = open $input | parse-input
  let x = $system.0 | get-value x -b | print
  let y = $system.0 | get-value y -b | print
  # let z = [$x $y] | print
  let z_ = main silver $input | print
  $system.1 | sort | inspect
  '' | print $'Gold:> ($in)'
}

# solution for day 2024/5
def main [rest] {
  main gold $rest
  return
  main silver $rest | print $'Silver:> ($in)'
}

def parse-input [] {
  split row -r '\n\n'
  | update 0 {lines | parse '{key}: {val}' | update val {into int} | transpose -dr}
  | update 1 {lines | parse '{in1} {op} {in2} -> {out}' | each {{
    in: ([$in.in1 $in.in2] | sort)
    op: $in.op out: $in.out
  }}}
}
