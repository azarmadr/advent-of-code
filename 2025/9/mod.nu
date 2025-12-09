$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *
use .../nu/utils.nu *

def area [] {
  ($in.ax - $in.bx | math abs | $in + 1) * (
  $in.ay - $in.by | math abs | $in + 1)
}

def silver [] {
  combinations $in
  | par-each {{ax: $in.0.x ay: $in.0.y
    bx: $in.1.x by: $in.1.y}}
  | par-each {area}
  | math max
}

def point-inside [$p $polygon] {
  # {point: $p} | table -e | print
  if $p in $polygon {return true}
  $polygon | append [$polygon.0]
  | window 2 -s 1
  | reduce -f false {|l res|
    let ys = [$l.0.y $l.1.y] | sort
    let xs = [$l.0.x $l.1.x] | sort
    if $p.y > $ys.0 {
      if $p.y <= $ys.1 {
	if $p.x <= $xs.1 {
	  let intersection = ($p.y - $l.0.y) * ($l.1.x - $l.0.x) / ($l.1.y - $l.0.y) + $l.0.x
	  if $xs.0 == $xs.1 or $p.x <= $intersection {
	    return (not $res)
	  }
	}
      }
    }
    $res
  }
  # do {print $in; $in}
}

def rect-outside-area [$p $polygon] {
  # {points: $p} | table -e | print
  [{x: $p.ax y:$p.by} {x: $p.bx y:$p.ay}]
  | all {point-inside $in $polygon}
}

def print-polygon [] {
  let polygon = $in
  let range = $in | transpose -i
  | each {values | math max | $in + 2}
  0..$range.0
  | each {
    0..$range.1 | each {{$in: .}} | reduce {|i| merge $i}}
  | table -e
  | print
}

def gold [] {
  let polygon = $in
  # $in | print-polygon
  combinations $in
  | par-each {{ax: $in.0.x ay: $in.0.y
    bx: $in.1.x by: $in.1.y}}
  | par-each {if (
    $in.ax == $in.bx or
    $in.ay == $in.by or
    (rect-outside-area $in $polygon)
  ) {area} else {0}}
  | math max
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) {
    '7,1
    11,1
    11,7
    9,7
    9,5
    2,5
    2,3
    7,3'
    | lines | str trim | str join "\n"
    | save -f sample.txt
  }
  open $input
  | lines
  | parse '{x},{y}'
  | update cells {into int}
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
