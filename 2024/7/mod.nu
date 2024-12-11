$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def calculate-valid-equations [] {
  $in
  | filter {$in.valid}
  | get calibration
  | math sum
}

def "main silver" [input: path, ] {
  open $input
  | parse-input
  | calculate-valid-equations
}

def can-remove-concatenation [i] {
  into string
  | parse -r  ('(.+)' + $'($i)$')
  | get capture0
  | into int
}

def three-way-calibration [i] {
    $i.nums
    | skip 1
    | reverse
    | reduce -f [$i.calibration] {|i, a|
      $a
      | each {[($in - $i) ($in / $i) ...(
        $in | can-remove-concatenation $i
      )]}
      | flatten
      | filter {$in == ($in | into int) and $in > 0}
      | into int
    }
    | any {$in == $i.nums.0}
}

def "main gold" [input: path, ] {
  open $input
  | parse-input
  | insert x_valid {|i| $i.valid or (three-way-calibration $i)}
  | update valid {|i| $i.valid or $i.x_valid}
  | calculate-valid-equations
}

# solution for day 2024/7
def main [rest] {
  main gold $rest | print Gold> $in
  main silver $rest | print Silver> $in
}

def parse-input [] {
  parse '{calibration}: {nums}'
  | update nums {split words}
  | update cells {into int}
  | insert valid {|i|
    $i.nums
    | skip 1
    | reverse
    | reduce -f [$i.calibration] {|i, a|
      $a | each {[($in - $i) ($in / $i)]}
      | flatten
      | filter {$in == ($in | into int) and $in > 0}
      | into int
    }
    | any {$in == $i.nums.0}
  }
}
