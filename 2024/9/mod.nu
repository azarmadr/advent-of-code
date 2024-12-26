$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input
  | parse-input
  | do {
    mut i = $in
    mut o = $i | take 1
    $i = $i | skip
    [{i:$i o:$o}] | table -e | print
    while ($i | is-not-empty) {
      if ($i | last | $in.id) == . {
        $i = $i | drop
        continue
      }
      if $i.0.id != . {
        $o = $o ++ $i.0
        $i = $i | skip
        continue
      }
      let last = $i | last
      let gap = $i | first
      if $gap.len > $last.len {
        $o = $o ++ $last
        $i = $i | drop | update 0 {update len {$in - $last.len}}
      } else if $gap.len < $last.len {
        $o = $o
        | append ($last | update len {$gap.len})
        $i = $i | update ($i | length | $in - 1) {
          update len {$in - $gap.len}
        } | skip 1
      } else {
        $o = $o ++ $last
        $i = $i | skip 1 | drop 1
      }
      # print $'($i | length) - ($o | length)'
      # [{i:$i o:$o last: $last gap: $gap}] | table -e | print
    }
    $o
  }
  | each {|i| seq 1 $i.len | each {$i.id}}
  | flatten
  | enumerate
  | each {$in.index * $in.item}
  | math sum
}

def "main gold" [input: path, ] {
  open $input | parse-input
  | do {
    mut i = $in
    mut o = $i | take 1
  }
}

# solution for day 2024/5
def main [rest] {
  main silver $rest | print 'Silver:>' $in
  return
  main gold $rest | print 'Gold:>' $in
}

def parse-input [] {
  split chars
  | each {try {into int}}
  | chunks 2
  | enumerate
  | each {|i| $i.item
    | enumerate
    | update index {if $in == 0 {$i.index} else {'.'}}
    | each {|i| {id: $i.index len: $i.item}}
    | where len > 0
  }
  | flatten
}
