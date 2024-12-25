$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

const KEY_CHANGES = [[from to instruction];
  ['0'  A  >A] ['0' '8' ^^^A] ['0' '2' ^A]
  ['1' '4' ^A] ['1' '7' ^^A]  ['1' '9' ^^>>A]
  ['2' '8' ^^A] ['2' '9' ^^>A]
  ['3' 'A' vA] ['3' '1' <<A] ['3' '7' <<^^A]
  ['4' '3' v>>A] ['4' '5' >A]
  ['5' 'A' vv>A] ['5' '6' >A]
  ['6' 'A' vvA]
  ['7' '8' >A] ['7' '9' >>A]
  ['8' '0' vvvA] ['8' '5' vA] ['8' '6' v>A] ['8' '9' >A]
  ['9'  A  vvvA] ['9' '8' <A]
  [A '0' <A] [A '1' ^<<A] [A '2' <^A] [A '3' ^A]
  [A '4' ^^<<A] [A '7' ^^^<<A] [A '9' ^^^A]
  [A A A]    [A ^ <A]  [A < v<<A] [A v <vA] [A > vA]
  [^ A >A]   [^ ^ A]   [^ < v<A]            [^ > v>A]
  [< A >>^A] [< ^ >^A] [< < A]    [< v >A]
  [> A ^A]   [> ^ <^A]            [> v <A]  [> > A]
  [v A ^>A]            [v < <A]   [v v A]   [v > >A]
]

def 'inspect print' [] {
  do {$in | table -e | print; $in}
}

def get-robot-inst [] {
    split chars
    | 'A' ++ $in | zip ($in | skip)
    | par-each -k {|pair| $KEY_CHANGES
      | where from == $pair.0 and to == $pair.1
      | if ($in | is-empty) {
        panic $'instruction ($pair) not found in $KEY_CHANGES'
      } else {$in.instruction.0}
    }
    | str join
}

def gen-robot-inst [-d: int -c: int = 0 shrink: bool] {
  insert ($c + 1 | $'robot-($in)') {|r| $r
    | get ($c | $'robot-($in)')
    | get-robot-inst
  }
  | flatten
  | if not $shrink {$in} else {reject $'robot-($c)'}
  | if $c != $d - 1 {
    gen-robot-inst -d $d -c ($c + 1) $shrink
  } else {
    rename -c {$'robot-($d)': final}
    | insert length {$in.final | str length}
    | insert score {$in.value * $in.length}
    | move length score --after value
    | get score | math sum
  }
}

def gen-robot-inst-compressed [-d: int -c: int = 0] {
  update inst {
    update value {
      get-robot-inst
      | split row A
      | drop
      | each {$in + A}
    }
    | flatten
    | group-by value --to-table
    | rename value count
    | update count {get count | math sum}
  } # do { $in.0.inst | inspect print; $in}
  | if $c != $d - 1 {
    gen-robot-inst-compressed -d $d -c ($c + 1)
  } else {
    insert score {|r| $r.value * (
      $r.inst
      | each {$in.count * ($in.value | str length)}
      | math sum
    )}
    | get score | math sum 
  }
}

def "main silver" [input: path, ] {
  open $input | parse-input
  | gen-robot-inst -d 3 false
}

def "main gold" [input: path, -d: int = 26] {
  open $input | parse-input
  | rename -c {robot-0: inst}
  | update inst {uniq -c}
  | gen-robot-inst-compressed -d $d
}

# solution for day 2024/5
def main [rest] {
  timeit {main gold $rest     | print $'Gold:> ($in)'} | print
  timeit {main gold $rest -d 3| print $'Gold:> ($in)'} | print
  return
  timeit {main silver $rest | print $'Silver:> ($in)'} | print
}

def parse-input [] {
  lines
  | wrap robot-0
  | insert value {$in.robot-0 | str substring 0..-2 | into int}
}
