# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  let data = open $input | parse-input
  $data.updates
  | filter {|i|
    $i
    | drop
    | enumerate
    | all {|j|
      $i | skip ($j.index + 1) | all {$in in ($data.pos | get $j.item -i | default [])}
    }
  }
  | each {skip ((($in | length) - 1) / 2 ) | first}
  | into int
  | math sum
  | to json
}

# solution for day 2024/5
def main [] {
  main silver --help
  # main gold -h
}

def parse-input [] {
  {
    pos: (
      $in
      | lines
      | parse '{pre}|{post}'
      | reduce -f {} {|el, acc| $acc | upsert $el.pre {append $el.post} }
    )
    updates: (
      $in
      | lines
      | filter {$in =~ ','}
      | each {split row ','}
    )
  }
}
