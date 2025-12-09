$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

def paths-to-out-from [$start out=out -w: string] {
  let graph = $in
  generate {|i|
    if ($i | all {last | $in == $out}) {return {}}
    $i
    | par-each {|i|
      if ($i | uniq -d | is-not-empty) {return []}
      let last = $i | last
      if $last == $out { return [$i] }
      $graph | get $last | each {$i ++ [$in]}
      | if $w == null {} else {where $w not-in $it}
    }
    | flatten
    # do {each {str join ' '} | print $in; $in}
    | {out: $i next: $in}
  } [[$start]]
  | last
}

def heads-to-out-from [$start out=out -w: list<string>] {
  let graph = $in
  generate {|i|
    if ($i | all {$in.head == $out}) {return {}}
    $i
    | par-each {|i|
      if $i.head == $out { return [$i] }
      $graph | get $i.head
      | each {|h|
	$i | update head $h
	| if $h in $w {update w {|i| append $h | sort}} else {}
      }
    }
    | flatten
    | group-by --to-table head w
    | update w {|i| $i.items.0.w}
    | update items {get items | math sum}
    | sort-by w
    | sort-by {$in.head == out}
    | do {update w {str join ' '} | wrap name | grid | print; $in}
    | {out: $i next: $in}
  } [{head: $start items: 1 w: []}]
  | last
}
def silver [] {
  paths-to-out-from you | length
}

def gold [] {
  heads-to-out-from svr -w [dac fft]
  | where $it.w == [dac fft]
  | get items
  | math sum
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) {
    'svr: aaa bbb
    you: svr
    aaa: fft
    fft: ccc
    bbb: tty
    tty: ccc
    ccc: ddd eee
    ddd: hub
    hub: fff
    eee: dac
    dac: fff
    fff: ggg hhh
    ggg: out
    hhh: out'
    | lines | str trim | str join "\n"
    | save -f sample.txt
  }
  if not ('sample1.txt' | path exists) {
    'aaa: you hhh
    you: bbb ccc
    bbb: ddd eee
    ccc: ddd eee fff
    ddd: ggg
    eee: out
    fff: out
    ggg: out
    hhh: ccc fff iii
    iii: out'
    | lines | str trim | str join "\n"
    | save -f sample1.txt
  }
  open $input
  | lines | parse '{i}: {o}'
  | update o {split row ' '}
  | transpose -rd
}
def run [input] {
  let input = parse-input $input
  {}
  | insert gold {$input | gold}
  | insert silver {$input | silver}
}

def main [i=0, -v] {
  let input = [input.txt sample.txt] | get $i
  if $v {debug profile -l -m 3 { run $input}
    | move duration_ms --after line
    | reject file
  } else {run $input}
}
