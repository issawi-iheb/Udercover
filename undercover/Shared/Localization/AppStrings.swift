//
//  AppStrings.swift
//  undercoverApp
//

import Foundation

public struct AppStrings: Sendable {
    public let language: AppLanguage

    public var voteOut: String {
        switch language {
        case .english:  return "VOTE OUT"
        case .french:   return "ÉLIMINER"
        case .arabic:   return "صوّت للإقصاء"
        case .spanish:  return "VOTAR"
        case .tunisian: return "حوت برا"
        }
    }

    public var whoIsUndercover: String {
        switch language {
        case .english:  return "Who is the Undercover?"
        case .french:   return "Qui est l'Undercover ?"
        case .arabic:   return "من هو العميل السري؟"
        case .spanish:  return "¿Quién es el infiltrado?"
        case .tunisian: return "شكون هو المتنكر؟"
        }
    }

    public var confirmVote: String {
        switch language {
        case .english:  return "Confirm Vote"
        case .french:   return "Confirmer le vote"
        case .arabic:   return "تأكيد التصويت"
        case .spanish:  return "Confirmar voto"
        case .tunisian: return "أكد الصوت"
        }
    }

    public var theUndercoverWas: String {
        switch language {
        case .english:  return "THE UNDERCOVER WAS"
        case .french:   return "L'UNDERCOVER ÉTAIT"
        case .arabic:   return "كان العميل السري"
        case .spanish:  return "EL INFILTRADO ERA"
        case .tunisian: return "المتنكر كان"
        }
    }

    public var civilians: String {
        switch language {
        case .english:  return "Civilians"
        case .french:   return "Civils"
        case .arabic:   return "المدنيون"
        case .spanish:  return "Civiles"
        case .tunisian: return "المدنيين"
        }
    }

    public var undercover: String {
        switch language {
        case .english:  return "Undercover"
        case .french:   return "Undercover"
        case .arabic:   return "العميل السري"
        case .spanish:  return "Infiltrado"
        case .tunisian: return "المتنكر"
        }
    }
    
    public var mrWhite: String {
        switch language {
        case .english:  return "Mr. White"
        case .french:   return "Mr. White"
        case .arabic:   return "السيد الأبيض"
        case .spanish:  return "Sr. White"
        case .tunisian: return "مستر وايت"
        }
    }

    public var replaySameTeam: String {
        switch language {
        case .english:  return "Replay — Same Team"
        case .french:   return "Rejouer — Même équipe"
        case .arabic:   return "إعادة — نفس الفريق"
        case .spanish:  return "Repetir — Mismo equipo"
        case .tunisian: return "ألعب مرة أخرى"
        }
    }

    public var newGame: String {
        switch language {
        case .english:  return "New Game"
        case .french:   return "Nouvelle partie"
        case .arabic:   return "لعبة جديدة"
        case .spanish:  return "Nueva partida"
        case .tunisian: return "لعبة جديدة"
        }
    }

    public var generatingWords: String {
        switch language {
        case .english:  return "Generating words…"
        case .french:   return "Génération des mots…"
        case .arabic:   return "جارٍ توليد الكلمات…"
        case .spanish:  return "Generando palabras…"
        case .tunisian: return "كيجيب كلام…"
        }
    }

    public var discussAndDeduce: String {
        switch language {
        case .english:  return "DISCUSS AND DEDUCE"
        case .french:   return "DISCUTEZ ET DÉDUISEZ"
        case .arabic:   return "ناقش واستنتج"
        case .spanish:  return "DISCUTE Y DEDUCE"
        case .tunisian: return "ناقش وفكر"
        }
    }

    public var seconds: String {
        switch language {
        case .english:  return "seconds"
        case .french:   return "secondes"
        case .arabic:   return "ثانية"
        case .spanish:  return "segundos"
        case .tunisian: return "ثواني"
        }
    }

    public var startVotingNow: String {
        switch language {
        case .english:  return "Start Voting Now"
        case .french:   return "Passer au vote"
        case .arabic:   return "ابدأ التصويت الآن"
        case .spanish:  return "Votar ahora"
        case .tunisian: return "ابدأ التصويت"
        }
    }

    public var findUndercover: String {
        switch language {
        case .english:  return "Find the Undercover"
        case .french:   return "Trouvez l'Undercover"
        case .arabic:   return "ابحث عن العميل السري"
        case .spanish:  return "Encuentra al infiltrado"
        case .tunisian: return "لقى المتنكر"
        }
    }

    public var discussClues: String {
        switch language {
        case .english:  return "Share clues without revealing your word."
        case .french:   return "Partagez des indices sans révéler votre mot."
        case .arabic:   return "شارك الأدلة دون الكشف عن كلمتك."
        case .spanish:  return "Comparte pistas sin revelar tu palabra."
        case .tunisian: return "تكلم بدون ما تقول الكلمة."
        }
    }

    public func round(_ n: Int) -> String {
        switch language {
        case .english:  return "Round \(n)"
        case .french:   return "Manche \(n)"
        case .arabic:   return "الجولة \(n)"
        case .spanish:  return "Ronda \(n)"
        case .tunisian: return "الدور \(n)"
        }
    }
    
    public func difficultyLabel(_ difficulty: PairDifficulty) -> String {
        switch language {
        case .english:
            switch difficulty {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }

        case .french:
            switch difficulty {
            case .easy: return "Facile"
            case .medium: return "Moyen"
            case .hard: return "Difficile"
            }

        case .arabic:
            switch difficulty {
            case .easy: return "سهل"
            case .medium: return "متوسط"
            case .hard: return "صعب"
            }

        case .spanish:
            switch difficulty {
            case .easy: return "Fácil"
            case .medium: return "Medio"
            case .hard: return "Difícil"
            }

        case .tunisian:
            switch difficulty {
            case .easy: return "ساهل"
            case .medium: return "متوسط"
            case .hard: return "صعيب"
            }
        }
    }
    
    public var languageSection: String {
        switch language {
        case .english:  return "Language"
        case .french:   return "Langue"
        case .arabic:   return "اللغة"
        case .spanish:  return "Idioma"
        case .tunisian: return "اللغة"
        }
    }

    public var players: String {
        switch language {
        case .english:  return "PLAYERS"
        case .french:   return "JOUEURS"
        case .arabic:   return "اللاعبون"
        case .spanish:  return "JUGADORES"
        case .tunisian: return "اللاعبين"
        }
    }

    public var playerNamePlaceholder: String {
        switch language {
        case .english:  return "Player name…"
        case .french:   return "Nom du joueur…"
        case .arabic:   return "اسم اللاعب…"
        case .spanish:  return "Nombre del jugador…"
        case .tunisian: return "اسم اللاعب…"
        }
    }

    public var addAtLeastThreePlayers: String {
        switch language {
        case .english:
            return "Add at least 3 players to start"
        case .french:
            return "Ajoutez au moins 3 joueurs pour commencer"
        case .arabic:
            return "أضف 3 لاعبين على الأقل للبدء"
        case .spanish:
            return "Añade al menos 3 jugadores para empezar"
        case .tunisian:
            return "زيد 3 لاعبين على الأقل باش تبدأ"
        }
    }

    public var topic: String {
        switch language {
        case .english:  return "TOPIC"
        case .french:   return "THÈME"
        case .arabic:   return "الموضوع"
        case .spanish:  return "TEMA"
        case .tunisian: return "الموضوع"
        }
    }

    public var random: String {
        switch language {
        case .english:  return "Random"
        case .french:   return "Aléatoire"
        case .arabic:   return "عشوائي"
        case .spanish:  return "Aleatorio"
        case .tunisian: return "عشوائي"
        }
    }

    public var findingWords: String {
        switch language {
        case .english:  return "Finding words…"
        case .french:   return "Recherche des mots…"
        case .arabic:   return "جارٍ البحث عن الكلمات…"
        case .spanish:  return "Buscando palabras…"
        case .tunisian: return "نلوّجو على الكلمات…"
        }
    }

    public var startGame: String {
        switch language {
        case .english:  return "START GAME"
        case .french:   return "COMMENCER"
        case .arabic:   return "ابدأ اللعبة"
        case .spanish:  return "EMPEZAR"
        case .tunisian: return "ابدأ اللعبة"
        }
    }

    public func needMorePlayers(_ count: Int) -> String {
        switch language {
        case .english:
            return "Need \(count) more player\(count == 1 ? "" : "s")"

        case .french:
            return "Encore \(count) joueur\(count == 1 ? "" : "s") nécessaire\(count == 1 ? "" : "s")"

        case .arabic:
            return "تحتاج إلى \(count) لاعبين إضافيين"

        case .spanish:
            return "Necesitas \(count) jugador\(count == 1 ? "" : "es") más"

        case .tunisian:
            return "يلزمك \(count) لاعب\(count == 1 ? "" : "ين") آخر"
        }
    }

    public var lobby: String {
        switch language {
        case .english:  return "LOBBY"
        case .french:   return "SALON"
        case .arabic:   return "الردهة"
        case .spanish:  return "SALA"
        case .tunisian: return "اللوبي"
        }
    }

    public var setUpYourGame: String {
        switch language {
        case .english:  return "Set up your game"
        case .french:   return "Configurez votre partie"
        case .arabic:   return "إعداد اللعبة"
        case .spanish:  return "Configura tu partida"
        case .tunisian: return "حضّر لعبتك"
        }
    }
    
    public var mrWhiteDescription: String {
        switch language {
        case .english:
            return "One player gets no word and must bluff"
        case .french:
            return "Un joueur n'a pas de mot et doit bluffer"
        case .arabic:
            return "لا يحصل أحد اللاعبين على كلمة وعليه أن يخادع"
        case .spanish:
            return "Un jugador no recibe palabra y debe engañar"
        case .tunisian:
            return "لاعب ما ياخو حتى كلمة ولازمو يبلّف"
        }
    }
    
    public var difficulty: String {
        switch language {
        case .english:
            return "DIFFICULTY"
        case .french:
            return "DIFFICULTÉ"
        case .arabic:
            return "الصعوبة"
        case .spanish:
            return "DIFICULTAD"
        case .tunisian:
            return "الصعوبة"
        }
    }
}
