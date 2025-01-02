$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def "main silver" [input: path, ] {
  let i = open $input | parse-input
  mut map = $i.0
  $map | print
  for dir in $i.1 {
    if $dir not-in [< v > ^] {continue}
    if $dir in [^ v] {
      $map = $map | transpose -r | enumerate | flatten
    }
    let row = $map | find @
    $map = $map
    | update ($row.index.0 | into int) ($row
      | values
      | skip
      | flatten
      | str join
      | ansi strip
      | if $dir in [^ <] {
        str replace -r '\.(O*@)' '$1.'
      } else {
        str replace -r '(@O*)\.' '.$1'
      }
      | reduce-to-record {index: $row.index.0}
    )
    if $dir in [^ v] {
      $map = $map | transpose -r | enumerate | flatten
    }
    # $map | print $dir $in
    # input pause
  }
  $map | print
  $map
  | reduce -f [] {|i|
    append ($i
      | transpose k v
      | where v == O
      | each {[$i.index $in.k]}
    )
  }
  | each {into int | $in.0 * 100 + $in.1}
  | math sum
}

def "main gold" [input: path, ] {
  open $input | parse-input
}

def main [-v rest] {
  debug profile -l -m 3 {
    main silver $rest | print $'Silver:> ($in)'
    return
    main gold $rest | print $'Gold:> ($in)'
  }
  | move duration_ms --after line
  | reject file
  | if $v {print}
}

def reduce-to-record [a = {}] {
  split chars
  | enumerate
  | update index {into string}
  | reduce -f $a {|i|
    insert $i.index $i.item
  }
}

def parse-input [] {
  split row -r '\n\n'
  | update 0 {
    lines | each {reduce-to-record}
    | enumerate
    | flatten
    | update index {into string}
  }
  | update 1 {split chars}
}
