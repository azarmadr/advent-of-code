$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

const ADJ_GRID = [[-1 -1] [-1 0] [-1 1] [0 -1] [0 1] [1 -1] [1 0] [1 1]]

def "main silver" [] {
  each {enumerate}
  | enumerate
  | each {|i| $i.item
    | each {rename col roll}
    | insert row $i.index
    | move col --last
  }
  | flatten
  | where roll == @
  | do {let table = $in
    $table
    | sort-by row col
    | par-each -k {|r| $ADJ_GRID
      | each { [($r.row + $in.0) ($r.col + $in.1)] }
      | each {|i| $table | where row == $i.0 and col == $i.1}
      | flatten
      | length
      | do {print $'[($r.row) ($r.col)]'; $in}
    }
    | where $it < 4
    | length
  }
}

def "main gold" [] {
}

def run [input] {
  let input = parse-input $input
  $input | main gold | print $"Gold:>\n($in)"
  $input | main silver | print $"Silver:>\n($in)"
}
def main [input = sample.txt, -v] {
  let input = 'input.txt'
  if $v {debug profile -l -m 3 { run $input}
  | move duration_ms --after line
  | reject file
  } else {run $input}
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
  | lines
  | each {split chars}
}
