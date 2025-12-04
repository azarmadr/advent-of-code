def main [curr: int, year = 2025] {
  watch . -r true
  | where operation == Create and path !~ '~$'
  | where path !~ '.(jj|git).'
  | each {|e|
    print $e
    try {
      clear;timeit {nu $'($year)\($curr)\mod.nu'}
    }
  }
}
