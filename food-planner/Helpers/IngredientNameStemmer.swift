import Foundation

enum IngredientNameStemmer {
    static func stem(_ text: String) -> String {
        let tokens = text
            .split(separator: " ")
            .map { stemToken(String($0)) }
            .filter { !$0.isEmpty }
        return tokens.joined(separator: " ")
    }

    private static func stemToken(_ raw: String) -> String {
        var token = raw.lowercased().replacingOccurrences(of: "ё", with: "е")
        guard token.count >= 3 else { return foldRussianOrthography(token) }

        if containsCyrillic(token) {
            return foldRussianOrthography(stemRussian(token))
        }
        return stemEnglish(token)
    }

    private static func containsCyrillic(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x0400...0x04FF).contains(scalar.value)
        }
    }

    private static func foldRussianOrthography(_ word: String) -> String {
        var result = word
        let replacements = [
            ("яи", "яй"),
            ("цы", "ц"),
            ("ци", "ц"),
        ]
        for (from, to) in replacements {
            if result.contains(from) {
                result = result.replacingOccurrences(of: from, with: to)
            }
        }
        return result
    }

    private static func stemRussian(_ input: String) -> String {
        var word = input
        let beforeAdjectival = word

        let adjectival: [(String, String)] = [
            ("его", ""), ("ого", ""), ("ему", ""), ("ому", ""),
            ("ими", ""), ("ыми", ""), ("ее", ""), ("ие", ""),
            ("ые", ""), ("ое", ""), ("ей", ""), ("ий", ""),
            ("ый", ""), ("ой", ""), ("ем", ""), ("им", ""),
            ("ым", ""), ("ом", ""), ("их", ""), ("ых", ""),
            ("ую", ""), ("юю", ""), ("ая", ""), ("яя", ""),
            ("ою", ""), ("ею", ""),
        ]
        word = stripSuffix(word, endings: adjectival, minStem: 3)
        let strippedAdjectival = word != beforeAdjectival

        let longNoun: [(String, String)] = [
            ("иями", ""), ("ями", ""), ("ами", ""), ("ией", ""),
            ("иям", ""), ("ием", ""), ("ам", ""), ("ом", ""),
            ("ах", ""), ("ях", ""), ("ию", ""), ("ью", ""),
            ("ия", ""), ("ья", ""), ("ей", ""), ("ий", ""),
            ("ии", ""), ("ов", ""), ("ев", ""), ("ие", ""),
            ("ье", ""),
        ]
        word = stripSuffix(word, endings: longNoun, minStem: 3)

        if !strippedAdjectival {
            let shortNoun: [(String, String)] = [
                ("и", ""), ("е", ""), ("у", ""), ("ы", ""),
                ("ь", ""), ("ю", ""), ("а", ""), ("я", ""), ("о", ""),
            ]
            word = stripSuffix(word, endings: shortNoun, minStem: 3)
        } else if word.hasSuffix("ь"), word.count > 3 {
            word = String(word.dropLast())
        }

        if word.hasSuffix("нн"), word.count > 4 {
            word = String(word.dropLast())
        }

        return word
    }

    private static func stemEnglish(_ input: String) -> String {
        var word = input
        let endings: [(String, String)] = [
            ("ational", "ate"), ("tional", "tion"),
            ("ization", "ize"), ("ation", "ate"), ("ator", "ate"),
            ("iveness", "ive"), ("fulness", "ful"), ("ousness", "ous"),
            ("ies", "y"), ("ied", "y"), ("ing", ""), ("edly", ""),
            ("ed", ""), ("es", ""), ("s", ""),
        ]
        word = stripSuffix(word, endings: endings, minStem: 3)
        return word
    }

    private static func stripSuffix(
        _ word: String,
        endings: [(String, String)],
        minStem: Int
    ) -> String {
        let sorted = endings.sorted { $0.0.count > $1.0.count }
        for (ending, replacement) in sorted {
            guard word.hasSuffix(ending) else { continue }
            let stemLength = word.count - ending.count + replacement.count
            guard stemLength >= minStem else { continue }
            return String(word.dropLast(ending.count)) + replacement
        }
        return word
    }
}
