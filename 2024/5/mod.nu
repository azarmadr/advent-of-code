def get-middle [] {skip (((($in | length) - 1) / 2 )|into int) | first}
def sum-middle-entries [] {
  each {get-middle}
  | into int
  | math sum
}

def pos-contains [pos] {
  }

def correct-input [pos] {
  sort-by -c {|a, b| $b in ($pos | get $a -i | default [])}
}

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  let data = open $input | parse-input
  $data.valid | get item| sum-middle-entries
}

def "main gold" [input: path, ] {
  let data = open $input | parse-input
  $data.invalid | get item | inspect | each {correct-input $data.pos} | sum-middle-entries
}

# solution for day 2024/5
def main [rest] {
  print 'Silver'
  main silver $rest
  main gold $rest
}


def parse-input [] {
  let data = $in
  let pos = $data
    | lines
    | parse '{pre}|{post}'
    | reduce -f {} {|el, acc| $acc | upsert $el.pre {append $el.post} }
  {}
  | insert pos $pos
  | merge (
      $data
      | lines
      | filter {$in =~ ','}
      | each {split row ','}
      | each {|i|
        {res: ($i
        | drop
        | enumerate
        | all {|j|
          $i | skip ($j.index + 1) | all {$in in ($pos | get $j.item -i | default [])}
        }
        | if $in {'valid'} else {'invalid'}
        ), item: $i}
      }
      | group-by res
    )
}
