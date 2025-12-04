$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

const ADJ_GRID = [[-1 -1] [-1 0] [-1 1] [0 -1] [0 1] [1 -1] [1 0] [1 1]]

def compute-adj-slower [] {
  let table = $in | where roll == @
  $table
  | par-each {|r| $ADJ_GRID
    | each { [($r.row + $in.0) ($r.col + $in.1)] }
    | each {|i| $table | where row == $i.0 and col == $i.1}
    | flatten
    | length
    | wrap adj
    | merge $r
    | do {values | str join "\t" | if $in =~ '33' and $in =~ '3$' {print $in}; $in}
  }
  | sort-by row col
}

def get-matrix-items-path [] {
  zip [item item] | flatten | into cell-path
}

def compute-adj-count [] {
  let matrix = $in
  $matrix
  | par-each {|i|
    if ($i.row mod 66) == 0 {$i.row | print}
    $i.item
    | where item != .
    | par-each {|j| 
      $ADJ_GRID
      | each { zip [$i.row $j.col] | each {math sum} }
      | where $it not-has -1
      | each { get-matrix-items-path }
      | each {|p| $matrix | get $p -o}
      | where $it == @
      | length
      | if $in < 4 {
	$j | merge ($i.row | wrap row)
      }
    }
    | compact
  }
  | flatten
  | do {
    let liftable = $in  
    $liftable | length | wrap count
    | insert matrix {
      $liftable | each {[$in.row $in.col] | get-matrix-items-path}
      | reduce -f $matrix {|p| update $p .}
    }
  }
}

def "main silver" [] {$in.count}

def "main silver-slower" [] {
  where adj < 4 | length
}

def "main silver-newer" [] {
  enumerate | flatten
  | window 4 -s 2
  | enumerate
  | update index {|i| $i.item.0.index}
  | each {initial-steps2}
}

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

def "main gold-slower" [] {
  mut table = $in
  mut lifted = 0
  loop {
    if ($table | all {$in.adj >= 4}) {break}
    $table | length | wrap remaining-rolls | print
    $lifted += $table | where adj < 4 | length
    $table = $table | where adj >= 4 | reject adj | compute-adj
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

def initial-steps2 [] {
  each {enumerate | transpose -i | skip | rename -b {str replace -r '\D+' c}} | flatten
  | update item {|i|
    each {reject index | values | enumerate | rename col roll}
    | enumerate | flatten
    | update index {$in + $i.index}
    | rename row
    | flatten
    | compute-adj
  }
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
  | parse-input-internal
}

def parse-input-internal [] {
  each {[.] ++ $in} | [[]] ++ $in
  | each {enumerate | rename col} | enumerate | rename row
  | compute-adj-count
}

def parse-input-internal-slower [] {
  flatten-matrix
  | compute-adj-slower
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
