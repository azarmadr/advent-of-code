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

def inspect-res [name?] {
  if $name != null {print $name}
  $in.best? | if $in != null {print $'best: ($in)'}
  $in | reject -o best| items {|k v| $v
    | first 111
    | each {values | $'($in)' | str replace -a , ''}
    | $"($k)[($v | length)]\n($in| try {grid | lines | first 3 | str join "\n"})"
    | str trim
    | print
  }
  print '---'
  $in
}

def min-button-count-for-joltage [-o] {
  let m = $in # machine
  let ids = $m.buttons | get index
  let counts = {counts: ($m.buttons | each {0})
  jolts: $m.joltage}
  0..81 | generate {|_ i|
    if $i.wip? == null {return {out: $i}}
    $i.wip
    | par-each {|c| $ids | each {|id|
      let b = $m.buttons | get $id
      $c
      | update ([counts $id] | into cell-path) {
	let count = $in
	if $b.rem == [] {
	  $count + 1
	} else {
	  let mult = $b.rem
	  | each {|o| $c.jolts | get $o}
	  | uniq | sort
	  if ($mult | length) > 1 {
	    $mult | last
	  } else if $mult.0 in [0 $count] {
	    $count + 1 # don't want to return the same
	  } else {
	    $mult.0
	  }
	}
      }
      | update jolts {|i| get-jolts $i.counts $m}
    }}
    | flatten
    | uniq
    | where not $o or $i.best? == null or ($it.counts | math sum) < $i.best
    | sort-by jolts
    | group-by {match $in.jolts {
      $x if ($x | all {$in == 0}) => 'res'
      $x if ($x | all {$in >= 0}) => 'wip'
      _ => 'failed'
    }}
    | insert best {
      if $in.res? == null {$i.best?} else {
	$in.res.counts | each {math sum}
	| where $i.best? == null or $it < $i.best
	| if $in == [] {$i.best} else {math min}
    }}
    | inspect-res
    | {out: $i next:$in}
  } {wip:[$counts]}
  | last | get best
}

def get-jolts [counts machine] {
  $counts
  | enumerate | flatten
  | reduce -f $machine.joltage {|c j| $machine.buttons.out
    | get $c.index
    | reduce -f $j {|i| update $i {$in - $c.item}}
  }
}

def gold [] {
  reject lights
  | update joltage {split row , | into int}
  | update buttons {
    sort | wrap out
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
  | first 2
  | each {
    inspect-machine 'gold'
    | min-button-count-for-joltage -o
  }
  | math sum
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
  | insert gold {$input | gold}
  # insert silver {$input | silver}
}

def main [i=0, -v] {
  let input = [input.txt sample.txt] | get $i
  if $v {debug profile -l -m 3 { run $input}
    | move duration_ms --after line
    | reject file
  } else {run $input}
}
