$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

def combination-gen [] {
  let items = $in
  1..($items | length)
  | generate {|e i|
    $i
    | each {|j| $items
      | where $it not-in $j
      | each {[...$j $in] | sort}
    }
    | flatten
    | uniq
    | {out: $i, next: $in}
  } ($items | each {[$in]})
  | flatten
}

def silver [] {
  update buttons {|i|
    combination-gen
    | where ($it | reduce -f $i.lights {|i a|
      $i | reduce -f $a {|i a| 
	$a | update $i {if $in == . {'#'} else {'.'}}
      }
    } | uniq) == [.]
    | first
    | length
  }
  | get buttons
  | math sum
}

def gold [] {
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) {
    '[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
    [...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    [.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}'
    | lines | str trim | str join "\n"
    | save -f sample.txt
  }
  open $input
  | lines
  | parse -r '\[(.*)\] (.*) \{(.*)\}'
  | rename lights buttons joltage
  | update buttons {
    split row ' '
    | each {split row -r \D | compact -e | into int}
  }
  | update lights {
    split row '' | compact -e
  }
}
def run [input] {
  let input = parse-input $input
  {}
  # insert gold {$input | gold}
  | insert silver {$input | silver}
}

def main [i=0, -v] {
  let input = [input.txt sample.txt] | get $i
  if $v {debug profile -l -m 3 { run $input}
    | move duration_ms --after line
    | reject file
  } else {run $input}
}
