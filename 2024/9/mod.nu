$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def check-sum [] {
  each {|i| seq 1 $i.len | each {$i.id}}
  | flatten
  | enumerate
  | update item {if $in == . {0} else {$in}}
  | each {$in.index * $in.item}
  | math sum
}

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
  | check-sum
}

def "main gold" [input: path, ] {
  open $input | parse-input
  | do {
    mut i = $in | enumerate | flatten
    mut id = $i | last
    while ($i | is-not-empty) and $id.id != 0 {
      let first_gap = $i
      | where id == . and len >= $id.len and index < $id.index
      | if ($in | is-not-empty) {first}
      if $first_gap != null {
        # $i | inspect
        [$id $first_gap] | move len --after index | print
        let move = $id
        $i = $i
        | update $id.index {update id {'.'}}
        | update $first_gap.index {[
          $move
          ($in | update len {$in - $move.len})
        ]}
        | flatten
        | reject index
        | where len > 0
        | chunk-by {$in.id == .}
        | each {if $in.0.id == . {
          group-by id --to-table 
          | rename id len
          | update len {get len | math sum}
        } else {$in}}
        | flatten
        | enumerate | flatten
      }
      if ($i | last | $in.id) == . {
        $i = $i | drop
      }
      $id = $i | where id == ($id.id - 1) | first
    }
    $i | reject index
  }
  | check-sum
}

# solution for day 2024/5
def main [rest] {
  main gold $rest | print 'Gold:>' $in
  return
  main silver $rest | print 'Silver:>' $in
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
