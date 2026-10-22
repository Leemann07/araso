import Foundation
import Testing
@testable import ArasoCore

/// The fork's Latin side is Norwegian (bokmål) + English, typed on the Norwegian layout: QWERTY's
/// letters with ø, æ, å on the ; ' [ keys. Korean 2-set stays on its keys.
@MainActor @Suite struct NorwegianTests {
    @Test func norwegianLayoutPutsLettersOnTheSymbolKeys() {
        let n = LatinLayout.norwegian
        #expect(n.character(onSeat: ";") == "ø")
        #expect(n.character(onSeat: "'") == "æ")
        #expect(n.character(onSeat: "[") == "å")
        #expect(n.character(onSeat: ":") == "Ø")
        #expect(n.character(onSeat: "e") == "e")
        #expect(n.seat(of: "ø") == ";")
        #expect(n.seat(of: "Å") == "{")
        #expect(n.character(keyCode: 41, shift: false, capsLock: false) == "ø") // the ; key
        #expect(n.character(keyCode: 39, shift: true, capsLock: false) == "Æ")  // the ' key
        #expect(n.character(keyCode: 33, shift: false, capsLock: true) == "Å")  // the [ key
        #expect(n.isLetterSeat("ø") && n.isLetterSeat("å") && n.isLetterSeat("æ"))
        #expect(!LatinLayout.qwerty.isLetterSeat("'"))
        for seat in "qwertyuiop[asdfghjkl;'zxcvbnmQWERTYUIOP{ASDFGHJKL:\"ZXCVBNM" {
            #expect(n.seat(of: n.character(onSeat: seat)) == seat)
        }
        // Other layouts leave the two new seats alone.
        #expect(LatinLayout.colemak.character(onSeat: "'") == "'")
        #expect(LatinLayout.colemak.character(onSeat: "[") == "[")
    }

    @Test(arguments: [
        "jeg", "ikke", "takk", "hyggelig", "selvfølgelig", "kjøpe", "blå", "øl", "på", "så",
        "norsk", "leilighet", "bilder", "fotograf", "visning", "eiendom", "sjø", "fjord", "været",
        "hello", "github", "the", "please",
    ])
    func norwegianAndEnglishWordsStayLatin(word: String) {
        LatinLayout.$override.withValue(.norwegian) {
            for previous in [nil, Language.english, .korean] {
                let d = sharedEngine.decide(word, context: DecisionContext(previousLanguage: previous))
                #expect(d.language == .english, "\(word) after \(String(describing: previous)) → \(d.output) \(d.explanation)")
                #expect(d.output == word)
            }
        }
    }

    @Test(arguments: [("dkssudgktpdy", "안녕하세요"), ("rkatkgkqslek", "감사합니다"), ("dhsmf", "오늘"), ("tkfkd", "사랑")])
    func koreanStaysOnItsKeys(keys: String, text: String) {
        LatinLayout.$override.withValue(.norwegian) {
            let d = sharedEngine.decide(keys, context: DecisionContext())
            #expect(d.language == .korean && d.output == text, "\(keys) → \(d.output) \(d.explanation)")
        }
    }

    /// A word with æ, ø or å can't be Korean at all: those keys have no jamo.
    @Test func extraLettersNeverReadAsKorean() {
        LatinLayout.$override.withValue(.norwegian) {
            #expect(HangulComposer.compose(keys: "blå") == nil)
            #expect(HangulComposer.compose(keys: "kjøpe") == nil)
            #expect(Language.korean.next(for: "blå") == .english)
            #expect(sharedEngine.english.isKnownWord("kjøpe"))
            #expect(sharedEngine.english.isKnownWord("kjøpte")) // kjøp + te through the stem
            #expect(sharedEngine.english.averageLogProbability("kjøpe") > -3)
        }
    }

    /// A Norwegian word with a Korean particle after it splits like an English one: kjøp에.
    @Test func norwegianWordPlusKoreanParticle() {
        LatinLayout.$override.withValue(.norwegian) {
            let engine = SplittingEngine(base: sharedEngine, english: sharedEngine.english)
            let d = engine.decide("kjøpdp", context: DecisionContext())
            #expect(d.language == .mixed && d.output == "kjøp에", "\(d.output) \(d.explanation)")
        }
    }
}
