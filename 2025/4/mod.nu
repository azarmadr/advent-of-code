$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

const ADJ_GRID = [[-1 -1] [-1 0] [-1 1] [0 -1] [0 1] [1 -1] [1 0] [1 1]]

def compute-adj [] {
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

def "main silver" [] {
  where adj < 4 | length
}

def "main gold" [] {
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
  open $input | lines | each {split chars}
}
def run [input] {
  let input = parse-input $input
  | flatten-matrix
  | compute-adj
  {}
  | insert gold {$input | main gold}
  | insert silver {$input | main silver}
}
def main [input = sample.txt, -v] {
  # let input = 'input.txt'
  if $v {debug profile -l -m 3 { run $input}
  | move duration_ms --after line
  | reject file
  } else {run $input}
}

