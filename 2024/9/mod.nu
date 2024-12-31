$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def check-sum [] {
  each {|i| seq 1 $i.len | each {$i.id}}
  | flatten
  | enumerate
  | each {$in.index * $in.item}
  | math sum
}

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input
  | parse-input
  | do {
    mut i = $in | skip
    mut o = $in | take 1
    [{i:$i o:$o}] | table -e | print
    while ($i | is-not-empty) {
      while ($i | last | $in.id) == . { $i = $i | drop }
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
    mut i = $in
    mut last_file = $i | last
    mut last_index = $i | length | $in - 1
    mut map = 0..9 | each {0} | enumerate | skip | transpose -dr

    while $last_file != null {
      # find the first gap
      mut first_gap = null
      for index in (seq ($map | get $'($last_file.len)') ($last_index - 1)) {
        let item = $i | get $index
        if $item.id == . and $item.len >= $last_file.len {
          $first_gap = $item | insert index $index
          for len in ($last_file.len)..9 {
            $map = $map | update $'($len)' {[$in $index] | math max}
          }
          break
        }
      }

      if $first_gap != null {
        # $i | inspect
        # [$id $first_gap] | move len --before id | print
        # $map | print
        let move = $last_file
        let len = $i | length
        $i = $i
        | update $last_index {update id {'.'}}
        | update $first_gap.index {
          update len {$in - $move.len}
          | if $in.len > 0 {
            [$move $in]
          } else {$move}
        }
        | flatten

        $last_index += ($i | length | $in - $len)
      }
      while ($i | last | $in.id) == . {
        $i = $i | drop
        $last_index -= 1
      }
      let next_id = $last_file.id - 1
      if $next_id == 0 {break}
      $last_file = null
      for index in ($last_index)..0 {
        let item = $i | get $index
        if $item.id == $next_id {
          $last_file = $item
          $last_index = $index
          break
        }
      }
      # $i | print
      # [{next:$id gap: $first_gap}] | table -e | print
    }
    $i
  }
  | update id {if $in == . {0} else {$in}}
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
