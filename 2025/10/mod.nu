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

def min-button-count [key final filter: closure cl: closure] {
  let machine = $in
  let start = $in | get $key
  generate {|i|
    if ($i | any {uniq | $in == [$final]}) {return {}}
    $i
    | par-each {|l| $machine.buttons | each {|b|
      $b.out | reduce -f $l {|o|
	update $o {do $cl $i}
      }
    }}
    | flatten
    | uniq
    | where (do $filter $it $start)
    | do {
      each {into int|str join ' '}| print $'($in | first 27 | grid -w 29)r: ($in | length)'
      $in
    }
    | {out: $i next:$in}
  } [$start]
}

def silver [] {
  update lights {each {$in == .}}
  | update buttons {sort | wrap out}
  | each {
    min-button-count lights true {|it start|
      $it != $start
    } {|_| not $in}
    | length
  }
  | math sum
}

def inspect-machine [i=def] {
  update joltage {str join ' '}
  | update buttons {each {update out {str join ' '}}
    | upsert rem {str join ' '}
  }
  | enumerate | flatten | rename $i
  | table -e
  | print
  $in
}

def min-button-count-for-joltage [] {
  let machine = $in
  let ids = $machine.buttons | get index
  generate {|i|
    if ($i.joltage | all {all {$in == 0}}) {return {}}
    $ids | each {|id| $i | par-each {|m| 
      let b = $m.buttons | get $id
      let mult = if $b.rem == [] {
	# if ($b.out | any {|o| ($m.joltage | get $o) < 1}) {
	#  return $m
	# }
	$b.mult + 1
      } else {
	let mult = $b.rem | each {|o| $m.joltage | get $o}
	| uniq
	if ($mult | length) > 1 {
	  $b.mult + 1
	} else if $mult.0 == 0 {
	  $b.mult + 1
	} else {
	  $m.joltage | get $b.rem.0
	}
      }
      $m
      | update ([buttons $id mult] | into cell-path) {
	$in + $mult}
      | update joltage {|j| $b.out
	| reduce -f $j.joltage {|i j|
	  $j | update $i {$in - $mult}
      }}
    }}
    | flatten
    | uniq
    | where ($it.joltage | all {$in >= 0})
    # inspect-machine 'updated'
    | do {length | print; $in}
    | {out: $i next:$in}
  } [$machine]
}

def gold [] {
  reject lights
  | update joltage {split row , | into int}
  | update buttons {
    sort | wrap out | insert mult {0}
    | move mult --first
    | enumerate | flatten
    | do {
      let buttons = $in
      | reverse
      $in
      | insert rem {|b|
	$b.out | each {|b|
	  $buttons | where $it.out has $b
	  | first
	  | {out: $b id: $in.index}
	}
	| where id == $b.index
	| get out
      }
    }
  }
  | first
  | inspect-machine 'gold'
  | each {min-button-count-for-joltage | last}
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
