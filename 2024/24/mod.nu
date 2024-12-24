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

def 'run-system load' [xy] {
  let system = $in
  $xy | each {bits-to-string}
}

def run-system [] {
  let system = $in
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
  [$reg $gates]
}

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input | parse-input | run-system | get 0 | get-value z
}

def "into num-string" [] {
  '00' + ($in | into string) | str replace -r '.*(..)$' '$1'
}

def bits-to-string [] {
  into bits | split row ' ' | reverse | str join | str reverse | str substring 0..45 | str reverse
}

def debug-system [
  -i: string
  -e: list<string>
  -d: int # depth
] {
  let d = $d | default 3
  if $d < 0 {return}
  let system = $in
  $system.1 | where out =~ $i | if $in != [] {inspect}
  | get in
  | flatten
  | filter {($e | is-empty) or ($in not-in $e)}
  | each {|i| $system | try {debug-system -d ($d - 1) -i $i -e $e}}
}

def "main gold" [input: path, ] {
  let system = open $input | parse-input
  let x = $system.0 | get-value x
  let y = $system.0 | get-value y
  let z = $system | run-system | $in.0 | get-value z
  let err = $z bit-xor $x + $y
  if $z == $x + $y {return 'pass'}
  let err_s = $err | bits-to-string
  $err_s | print
  let err_b = $err_s | str reverse | str index-of 1 | into num-string
  $system | debug-system -i $err_b -d 2
  ''
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
