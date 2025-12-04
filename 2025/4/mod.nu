$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

const ADJ_GRID = [[-1 -1] [-1 0] [-1 1] [0 -1] [0 1] [1 -1] [1 0] [1 1]]

def get-matrix-items-path [] {
  zip [item item] | flatten | into cell-path
}

def compute-adj-count [] {
  let matrix = $in
  | do {let i = $in; 0..1 | reduce -f $i {
    reverse | skip while {all {$in == .}}
  }}
  | each {reverse | skip while {$in == .} | reverse}
  | do {each {str join ''} | str join "\n" | print $in; $in}
  | [[]] ++ $in
  | each {enumerate | rename col} | enumerate | rename row

  $matrix
  | flatten | flatten | where item != . 
  # do {table -e | print; $in}
  | par-each {|i|
    $ADJ_GRID
    | each { zip [$i.row $i.col] | each {math sum} }
    | where $it not-has -1
    | each {|p| $matrix | get ($p | get-matrix-items-path) -o}
    | where $it == @
    | length
    | if $in < 4 {$i}
  }
  | compact
  | do {
    let liftable = $in  
    $liftable | length | wrap count
    | insert matrix {
      $liftable | each {[$in.row $in.col] | get-matrix-items-path}
      | reduce -f $matrix {|p| update $p .}
      | $in.item | each {$in.item}
    }
  }
}

def "main silver" [] {$in.count}

def "main gold" [] {
  mut table = $in
  mut lifted = 0
  loop {
    $lifted += $table.count
    $table | select count | print
    $table = $table.matrix | compute-adj-count
    if $table.count == 0 {break}
  }
  $lifted
}

def flatten-matrix [] {
  each {enumerate} | enumerate
  | each {|i| $i.item
    | each {rename col roll}
    | insert row $i.index
  }
  | flatten
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('ample.txt' | path exists) {
    '..@@.@@@@.
    @@@.@.@.@@
    @@@@@.@.@@
    @.@@@@..@.
    @@.@@@@.@@
    .@@@@@@@.@
    .@.@.@.@@@
    @.@@@.@@@@
    .@@@@@@@@.
    @.@.@@@.@.'
    | lines | str trim | str join "\n"
    | save -f sample.txt
  }
  open $input
  | lines | each {split chars}
  | each {[.] ++ $in}
  | compute-adj-count
}

def run [input] {
  let input = parse-input $input
  {}
  | insert gold {$input | main gold}
  | insert silver {$input | main silver}
}
def main [input = sample.txt, -v] {
  let input = 'input.txt'
  if $v {debug profile -l -m 3 { run $input}
  | move duration_ms --after line
  | reject file
  } else {run $input}
}
