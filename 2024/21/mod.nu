$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

const KEY_CHANGES = [[from to instruction];
  ['0'  A  >A]
  ['0' '8' ^^^A]
  ['0' '2' ^A]
  ['1' '4' ^A]
  ['1' '7' ^^A]
  ['1' '9' [>>^^A >>^^A]]
  ['2' '8' ^^A]
  ['2' '9' [^^>A >^^A]]
  ['3' 'A' vA]
  ['3' '1' <<A]
  ['3' '7' [<<^^A ^^<<A]]
  ['4' '3' [v>>A >>vA]]
  ['4' '5' >A]
  ['5' 'A' [vv>A >vvA]]
  ['5' '6' >A]
  ['6' 'A' vvA]
  ['7' '8' >A]
  ['7' '9' >>A]
  ['8' '0' vvvA]
  ['8' '5' vA]
  ['8' '6' [v>A >vA]]
  ['8' '9' >A]
  ['9'  A  vvvA]
  ['9' '8' <A]
  [A '0' <A]
  [A '1' ^<<A]
  [A '2' [<^A ^<A]]
  [A '3' ^A]
  [A '4' ^^<<A]
  [A '7' ^^^<<A]
  [A '9' ^^^A]
  [A < v<<A] [A > vA] [A ^ <A] [A v [<vA v<A]] [A A A]
  [^ ^ A] [^ > [v>A >vA]] [^ < <vA] [^ A >A]
  [< A ^>>A] [< < A] [< ^ ^>A] [< v >A]
  [> A ^A] [> > A] [> ^ ^<A] [> v <A]
  [v v A] [v A >^A] [v < <A] [v > >A]
]

def gen-robot-inst [from to] {
  insert $to {|r|
    $r
    | get $from
    | each {
      split chars
      | 'A' ++ $in | zip ($in | skip)
      | each {|pair| $KEY_CHANGES
        | where from == $pair.0 and to == $pair.1
        | if ($in | is-empty) {
          panic $'instruction ($pair) not found in $KEY_CHANGES'
        } else {$in.instruction}
      }
      | flatten
      | reduce {|i a| $a | each {|j| $i | each {$j + $in}}| flatten}
    }
    | flatten
  }
}

def "main silver" [input: path, ] {
  open $input | parse-input
  | wrap code
  | update code {[$in]}
  | gen-robot-inst code robot_inst1
  | gen-robot-inst robot_inst1 robot_inst2
  | gen-robot-inst robot_inst2 robot_inst3
  | insert length {$in.robot_inst3 | each {str length} | uniq}
  | insert score {($in.code.0 | str substring 0..-2 | into int) * ($in.length|math min)}
  | move length score --after code
  | do {$in | table -e | print; $in}
  | get score | math sum
}

def "main gold" [input: path, ] {
  open $input | parse-input
}

# solution for day 2024/5
def main [rest] {
  main silver $rest | print $'Silver:> ($in)'
  return
  main gold $rest | print $'Gold:> ($in)'
}

def parse-input [] {
  lines
}
