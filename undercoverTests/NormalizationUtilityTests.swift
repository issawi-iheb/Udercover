import Testing
@testable import undercover

struct NormalizationUtilityTests {

    @Test
    func normalize_handlesLowercase() {
        #expect(NormalizationUtility.normalize("HELLO") == "hello")
        #expect(NormalizationUtility.normalize("World") == "world")
    }

    @Test
    func normalize_handlesUppercase() {
        #expect(NormalizationUtility.normalize("hello") == "hello")
        #expect(NormalizationUtility.normalize("world") == "world")
    }

    @Test
    func normalize_handlesMixedCase() {
        #expect(
            NormalizationUtility.normalize("HeLLo WoRlD")
            == "hello world"
        )
    }

    @Test
    func normalize_handlesDiacritics() {
        #expect(NormalizationUtility.normalize("Café") == "cafe")
        #expect(NormalizationUtility.normalize(" naïve") == "naive")
        #expect(NormalizationUtility.normalize("résumé") == "resume")
        #expect(NormalizationUtility.normalize("ÉPISODÉ") == "episode")
        #expect(NormalizationUtility.normalize("Ångström") == "angstrom")
    }

    @Test
    func normalize_handlesPunctuation() {
        #expect(
            NormalizationUtility.normalize("Hello, World!")
            == "hello world"
        )

        #expect(
            NormalizationUtility.normalize("Nike's")
            == "nikes"
        )

        #expect(
            NormalizationUtility.normalize("McDonald's")
            == "mcdonalds"
        )

        #expect(
            NormalizationUtility.normalize("rock'n'roll")
            == "rocknroll"
        )
    }

    @Test
    func normalize_handlesCurlyApostrophe() {
        #expect(
            NormalizationUtility.normalize("Nike’s")
            == "nikes"
        )

        #expect(
            NormalizationUtility.normalize("McDonald’s")
            == "mcdonalds"
        )
    }

    @Test
    func normalize_handlesWhitespace() {
        #expect(
            NormalizationUtility.normalize("  hello  ")
            == "hello"
        )

        #expect(
            NormalizationUtility.normalize("\thello\tworld\n")
            == "hello world"
        )

        #expect(
            NormalizationUtility.normalize("  hello   world  ")
            == "hello world"
        )
    }

    @Test
    func normalize_handlesMultipleSpaces() {
        #expect(
            NormalizationUtility.normalize("hello   world")
            == "hello world"
        )

        #expect(
            NormalizationUtility.normalize("hello     world")
            == "hello world"
        )

        #expect(
            NormalizationUtility.normalize("hello\t\t\tworld")
            == "hello world"
        )
    }

    @Test
    func normalize_handlesMultiWordConcepts() {
        #expect(
            NormalizationUtility.normalize("New York")
            == "new york"
        )

        #expect(
            NormalizationUtility.normalize("Los Angeles")
            == "los angeles"
        )

        #expect(
            NormalizationUtility.normalize("San Francisco")
            == "san francisco"
        )
    }

    @Test
    func normalize_handlesEmptyAndNil() {
        #expect(NormalizationUtility.normalize("") == "")
        #expect(NormalizationUtility.normalize(nil) == "")
        #expect(NormalizationUtility.normalize("   ") == "")
        #expect(NormalizationUtility.normalize("\t\n\r") == "")
    }

    @Test
    func conceptsFromPair_returnsNormalizedSet() {
        let concepts = NormalizationUtility.conceptsFromPair(
            civilian: "New York",
            undercover: "Los Angeles"
        )

        #expect(
            concepts == Set([
                "new york",
                "los angeles"
            ])
        )
    }

    @Test
    func conceptsFromPair_deduplicatesIdenticalConcepts() {
        let concepts = NormalizationUtility.conceptsFromPair(
            civilian: "New York",
            undercover: "new york"
        )

        #expect(
            concepts == Set(["new york"])
        )
    }

    @Test
    func conceptsFromPair_normalizesPunctuationAndDiacritics() {
        let concepts = NormalizationUtility.conceptsFromPair(
            civilian: "Nike's",
            undercover: "Café"
        )

        #expect(
            concepts == Set([
                "nikes",
                "cafe"
            ])
        )
    }

    @Test
    func pairKey_isOrderIndependent() {
        let key1 = NormalizationUtility.pairKey("Nike", "Adidas")
        let key2 = NormalizationUtility.pairKey("Adidas", "Nike")

        #expect(key1 == key2)
        #expect(key1 == "adidas|nike")

        let key3 = NormalizationUtility.pairKey("Nike's", "Adidas")
        let key4 = NormalizationUtility.pairKey("adidas", "nikes")

        #expect(key3 == key4)

        let key5 = NormalizationUtility.pairKey("hello", "hello")
        #expect(key5 == "hello|hello")
    }

    @Test
    func pairKey_handlesVariousInputs() {
        #expect(
            NormalizationUtility.pairKey(
                "New York",
                "Los Angeles"
            ) == "los angeles|new york"
        )

        #expect(
            NormalizationUtility.pairKey(
                "Café",
                "naïve"
            ) == "cafe|naive"
        )

        #expect(
            NormalizationUtility.pairKey(
                "Nike's",
                "Adidas"
            ) == "adidas|nikes"
        )
    }
}
