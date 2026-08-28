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
}
