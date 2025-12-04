def main [curr: int, year = 2025] {
  watch . -r true {|op, path|
    $op | print
    if $op == 'Create' { try {
      clear;timeit {nu $'($year)\($curr)\mod.nu'}
    }}
  }
}
