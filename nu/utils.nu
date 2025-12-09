export def combinations [items: list<any>] {
    if ($items | length) < 2 { return [] }

    mut rest = $items
    mut $combinations = []
    loop {
      let $first = $rest | first
      $rest = $rest | skip
      if ($rest | is-empty) {return $combinations}
      $combinations ++= append ($rest | par-each {[$first $in]})
    }
}
