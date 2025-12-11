$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

const PROCESS_FIRST_N = 22

def combination-gen [] {
  let items = $in
  1..($items | length)
  | generate {|e i| $i
    | each {|j| $items
      | where $it not-in $j
      | each {[...$j $in] | sort}
    }
    | flatten | uniq
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
      each {into int|str join ' '}
      | print $'($in | first 27 | grid -w 29)r: ($in | length)'
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
  update jolts {|i| try {str join ' '} catch {$i}}
  | update buttons {each {update out {str join ' '}}
    | upsert rem {str join ' '}
  }
  | table -e | print
  $in
}

def inspect-res [] {
  print $'($in.dur) ($in.best? | if $in != null {$" best: ($in)"})'
  $in | reject -o best dur now | items {|k v| $v
    | first 27
    | each {values | $'($in)' | str replace -a , ''}
    | $"($k)[($v | length)]\n($in| try {
      grid | lines | first 3 | str join "\n"
    })"
    | str trim
    | print
  }
  print ''
  $in
}

def min-button-count-for-jolts [-o] {
  let m = $in # machine
  let buttons = $m.buttons | enumerate | flatten | rename index
  let counts = {counts: ($m.buttons | each {0})
  jolts: $m.jolts next-button-to-try: 0}
  let SIZE_LIMIT = 111 * ($buttons | length)
  let now = date now
  0.. | generate {|c i|
    # if $c > 999 {return {}}
    if (
      # $i.best? == null and $c > 499 or
      $i.wip? == null) {
      return {out: $i}}
    $i.wip
    | first $SIZE_LIMIT
    | par-each {|c| $buttons
    | where $c.next-button-to-try == $it.index
    | each {|b| 
      let mj = $b.out | each {|i| $c.jolts | get $i} | math min
      let rem = $b.rem | each {|i| $c.jolts | get $i} | uniq
      match $rem {
	[] => 0..$mj
	[$x] if $x <= $mj => $rem
	_ => []
      } | each {|p| # presses
	$c
	| update ([counts $b.index] | into cell-path) {$in + $p}
	| update jolts {|i| get-jolts $i.counts $m}
	| update next-button-to-try {$in + 1}
      }
    }}
    | flatten | flatten
    # | where next-button-to-try < ($buttons | length) or (
    #   $it.jolts | all {$in == 0})
    | where (not $o 
      or $i.best? == null
      or ($it.counts | math sum) < $i.best)
    | group-by {match $in.jolts {
      $x if ($x | all {$in == 0}) => 'res'
      $x if ($x | all {$in >= 0}) => 'wip'
      _ => 'failed'
    }}
    | upsert wip {append ($i.wip | skip $SIZE_LIMIT)}
    | compact -e
    | insert best {
      if $in.res? == null {$i.best?} else {
	$in.res.counts | each {math sum}
	| where $i.best? == null or $it < $i.best
	| if $in == [] {$i.best} else {math min}
    }}
    | insert now $i.now?
    | if $c mod 88 == 87 or $in.res? != null {
      upsert now (date now)
      | insert dur {|p| $'[($m.index):($c)] ([$i.now? $now] | compact
	| each {$p.now - $in | $in // 1sec * 1sec} | str join " | ")'}
      | do {$in.wip?.next-button-to-try | default [] | uniq -c
	| rename index $'c($m.index)' | sort-by index
	| transpose -rd | insert index $m.index | [$in]
	| print; $in}
      | inspect-res
    } else {}
    | if $in.wip? == null {{out: $in}} else {next:$in}
  } {wip:[$counts]}
  | last | {index: $m.index res: $in.best?}
}

def get-jolts [counts machine] {
  $counts
  | enumerate | flatten
  | reduce -f $machine.jolts {|c j| $machine.buttons.out
    | get $c.index
    | reduce -f $j {|i| update $i {$in - $c.item}}
  }
}

def sort-buttons-and-insert-rem [] {
  sort | wrap out | enumerate | flatten
  | do {
    let buttons = $in | reverse
    $in | insert rem {|b| $b.out
      | each {|b| $buttons | where $it.out has $b | first | update out $b}
      | where index == $b.index
      | get out
    }
  }
}

def substract-rows [mid] {
  let m = $in | enumerate | flatten
  let len = $m | length
  print -n $mid
  generate {|m|
    0..($len - 1) | reduce -f $m {|id a|
      update $id {$a | where index != $id
	| reduce -f ($a | get $id) {|r a|
	  let reduced = [$a $r] | transpose | skip
	  | each {values | [$in.0 ($in.1 - $in.2)]}
	  if ($reduced | any {$in.1 < 0}) {$a} else {
	    print -n $'> ($id) - ($r.index)'
	    $reduced | reduce -f {index: $id} {|i|
	      insert $i.0 $i.1}
	  }
	}
      }
    }
    | if $m == $in {{out: $in}} else {next: $in}
  } $m
  | last
  | tee {print '>' ;
    $in | rename index $'jolt($mid)'
    | update cells {if $in == 0 {''} else {}}
    | print}
}

def rref [m] {
  [$m.jolts]
  | append ($m.buttons | each {
    reduce -f $m.jolts {|bo a| update $bo (-1)}
    | each {$in == -1 | into int}
    })
  | each {wrap x | transpose -i}
  | flatten | transpose -i
  | rename jolt
  | rename -b {str replace column c}
  | substract-rows $m.index
  | where jolt != 0
  | do { let r = $in
    $m
    | update jolts $r.jolt
    | update buttons { $r
      | reject jolt index | transpose -i
      | each {values | enumerate | where item == 1 | $in.index}
      | where $it != []
    }
  }
}

def rearrange-jolts-by-buttons-available [] {
  let m = $in # machine
  let n = $m.jolts # new arrangement
  | enumerate
  | each {|i|
    let buttons_with_out = $m.buttons | where $it has $i.index
    let lengths = $buttons_with_out | each {length}
    $i | merge {min: ($lengths | math min) max: ($lengths | math max)
      count: ($buttons_with_out | length | $in * -1)}
  }
  | sort-by min max count -r
  | enumerate | flatten
  | rename index prev-index item $'min ($m.index)'
  | tee {print}
  $m
  | update jolts {$n.item}
  | update buttons {each {
    each {|i| $n | where prev-index == $i | $in.0.index}
    | sort
  }}
}

def gold [] {
  let file = $'res-($in | length).nuon'
  let cache = try {open $file | compact res} | default []
  $in | reject lights
  | enumerate | flatten
  | where index not-in $cache.index
  # | first $PROCESS_FIRST_N
  | update jolts {split row , | into int}
  | each {rref $in}
  | each {rearrange-jolts-by-buttons-available}
  | update buttons {sort-buttons-and-insert-rem}
  | tee {each {update buttons {$in.out} | rref $in}}
  | tee {each {inspect-machine}}
  | par-each -t 3 {min-button-count-for-jolts -o}
  | compact
  | if $in != [] {append $cache | sort | tee {save -f $file}}
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
  | rename lights buttons jolts
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
