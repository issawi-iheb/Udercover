//
//  LocalWordGenerator.swift
//  undercoverApp
//
//  Fully offline. Actor for Swift 6 safety.
//  Strategy: WordRepository first → adjacent difficulty bands → static vocabulary generation.
//

import Foundation

public actor LocalWordGenerator: WordGeneratorProtocol {

    public let generatorName = "Local (Offline)"
    public var isAvailable:   Bool { true }

    private let repository = WordRepository()
    private let scorer     = SimilarityScorer()

    // MARK: - Protocol

    public func randomPair(
        topic:      String,
        language:   AppLanguage,
        difficulty: PairDifficulty,
        excluding:  Set<String>
    ) async throws -> WordPair {

        // 1. Exact difficulty match from repository.
        if let pair = await repository.randomPair(topic: topic, language: language,
                                            difficulty: difficulty, excluding: excluding) {
            return pair
        }

        // 2. Relax difficulty — try other bands.
        for relaxed in PairDifficulty.allCases where relaxed != difficulty {
            if let pair = await repository.randomPair(topic: topic, language: language,
                                                difficulty: relaxed, excluding: excluding) {
                return pair
            }
        }

        // 3. Generate from static vocabulary using Jaro-Winkler.
        if let pair = generateFromVocabulary(topic: topic, language: language,
                                             difficulty: difficulty, excluding: excluding) {
            return pair
        }

        throw WordGeneratorError.noPairsAvailable
    }

    // MARK: - Vocabulary generation

    private func generateFromVocabulary(
        topic:      String,
        language:   AppLanguage,
        difficulty: PairDifficulty,
        excluding:  Set<String>
    ) -> WordPair? {

        let vocab       = vocabulary(for: topic, language: language)
        guard vocab.count >= 2 else { return nil }

        let targetRange = difficulty.scoreRange
        let maxAttempts = vocab.count * vocab.count
        var attempts    = 0

        while attempts < maxAttempts {
            guard let w1 = vocab.randomElement(),
                  let w2 = vocab.randomElement(),
                  w1 != w2 else { attempts += 1; continue }

            let n1 = w1.lowercased()
            let n2 = w2.lowercased()

            guard !excluding.contains(n1) else { attempts += 1; continue }

            let sim = scorer.jaroWinkler(n1, n2)
            guard targetRange.contains(sim), scorer.isPlayable(n1, n2) else {
                attempts += 1; continue
            }

            return WordPair(
                civilian:   LocalizedWord(values: allLangs(w1)),
                undercover: LocalizedWord(values: allLangs(w2)),
                topic:      topic,
                similarity: sim
            )
        }
        return nil
    }

    private func allLangs(_ word: String) -> [String: String] {
        ["en": word, "ar": word, "fr": word, "es": word, "tn": word]
    }

    // MARK: - Vocabulary selection

    private func vocabulary(for topic: String, language: AppLanguage) -> [String] {
        let repoWords = repository.allPairs(for: topic).flatMap {
            [$0.civilian.localized(for: language), $0.undercover.localized(for: language)]
        }
        if repoWords.count >= 10 { return Array(Set(repoWords)) }
        return staticVocabulary(topic: topic, language: language)
    }

    private func staticVocabulary(topic: String, language: AppLanguage) -> [String] {
        switch language {
        case .english, .french, .spanish: return englishVocab[topic] ?? genericEnglish
        case .arabic:                      return arabicVocab[topic]  ?? genericArabic
        case .tunisian:                    return tunisianVocab[topic] ?? genericTunisian
        }
    }

    // MARK: - Static word lists

    private let genericEnglish = [
        "water","fire","earth","air","stone","cloud","moon","sun","star","river",
        "ocean","mountain","valley","forest","desert","field","bridge","road","castle","tower"
    ]
    private let genericArabic = [
        "ماء","نار","تراب","هواء","حجر","سحابة","قمر","شمس","نجمة","نهر",
        "محيط","جبل","وادي","غابة","صحراء","حقل","جسر","طريق","قلعة","برج"
    ]
    private let genericTunisian = [
        "ماء","nar","trab","hwa","hjra","sahba","qamar","shams","njma","oued",
        "bhar","jbel","wadi","ghaba","sehra","ghorfa","qantra","triq","qal3a","borj"
    ]
    private let englishVocab: [String: [String]] = [
        "animals":    ["cat","dog","eagle","wolf","bear","fox","deer","hawk","crow","owl","frog","snake","rabbit","horse","lion","tiger","shark","whale","penguin","parrot","bat","beaver","zebra","giraffe","cheetah"],
        "food":       ["pizza","burger","sushi","cake","bread","soup","salad","pasta","steak","tacos","rice","curry","waffle","pancake","bagel","muffin","donut","pretzel","croissant","lasagna"],
        "sports":     ["football","tennis","boxing","swimming","cycling","golf","rugby","cricket","hockey","archery","wrestling","fencing","rowing","skiing","surfing","volleyball","basketball","marathon","sprint","diving"],
        "technology": ["laptop","tablet","robot","drone","camera","keyboard","server","battery","screen","headphones","printer","charger","scanner","smartwatch","satellite","transistor","circuit","antenna","cable","router"],
        "jobs":       ["doctor","teacher","lawyer","chef","pilot","engineer","architect","musician","journalist","farmer","dentist","mechanic","photographer","programmer","judge","nurse","sailor","sculptor","boxer","surgeon"],
        "cities":     ["Paris","Tokyo","London","Cairo","Dubai","Rome","Berlin","Moscow","Sydney","Beijing","Mumbai","Lagos","Seoul","Toronto","Istanbul","Madrid","Bangkok","Athens","Vienna","Warsaw"],
        "music":      ["guitar","piano","drums","violin","trumpet","flute","saxophone","cello","harp","tuba","clarinet","accordion","mandolin","banjo","oboe","trombone","harmonica","xylophone","sitar","didgeridoo"],
        "movies":     ["thriller","comedy","horror","romance","action","drama","fantasy","documentary","animation","western","mystery","musical","biopic","noir","satire","sci-fi","adventure","heist","spy","war"],
        "transport":  ["car","bus","train","plane","ship","bicycle","motorcycle","truck","tram","boat","helicopter","submarine","rocket","skateboard","canoe","kayak","taxi","ferry","ambulance","scooter"],
        "fruits":     ["apple","mango","grape","peach","lemon","banana","cherry","melon","plum","fig","kiwi","guava","papaya","coconut","pineapple","strawberry","blueberry","pomegranate","tangerine","watermelon"],
    ]
    private let arabicVocab: [String: [String]] = [
        "animals": ["قطة","كلب","نسر","ذئب","دب","ثعلب","غزال","صقر","غراب","بومة","ضفدع","أفعى","أرنب","حصان","أسد","نمر","قرش","حوت","بطريق","ببغاء"],
        "food":    ["بيتزا","برغر","سوشي","كيك","خبز","حساء","سلطة","معكرونة","لحم","أرز","كاري","وافل","قهوة","شاي","حليب","عصير","شوكولاتة","عسل","ملح","سكر"],
        "fruits":  ["تفاحة","مانجو","عنب","خوخ","ليمون","موز","كرز","شمام","برقوق","تين","كيوي","جوافة","بابايا","أناناس","فراولة","توت","رمان","يوسفي","بطيخ","جوز الهند"],
    ]
    private let tunisianVocab: [String: [String]] = [
        "animals": ["قطوس","كلب","نسر","ذيب","دب","ثعلب","غزال","بازي","غراب","بومة","ضفدع","حنش","قنية","عود","سبع","نمر","قرش","حوت","بطريق","ببغاء"],
        "food":    ["بيتزا","برغر","سوشي","كيكة","خبز","شربة","سلطة","مكرونة","كفتة","أرز","قهوة","شاي","حليب","عصير","شوكولاطة","عسل","ملح","سكر","زيت","تبولة"],
        "cities":  ["تونس","صفاقس","سوسة","نابل","بنزرت","قابس","قفصة","المنستير","جربة","زغوان","الكاف","باجة","سيدي بوزيد","قصرين","مدنين","تطاوين","أريانة","بن عروس","منوبة","الشاذلية"],
    ]
}
