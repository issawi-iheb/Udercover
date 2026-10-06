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
        case .tunisian: return "أكد التصويت"
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

    // MARK: - Accessibility Labels & Hints
    public var backButton: String {
        switch language {
        case .english:  return "Back"
        case .french:   return "Retour"
        case .arabic:   return "رجوع"
        case .spanish:  return "Atrás"
        case .tunisian: return "رجوع"
        }
    }

    public var backButtonHint: String {
        switch language {
        case .english:  return "Returns to the previous screen"
        case .french:   return "Retour à l'écran précédent"
        case .arabic:   return "العودة إلى الشاشة السابقة"
        case .spanish:  return "Vuelve a la pantalla anterior"
        case .tunisian: return "رجوع للشاشة السابقة"
        }
    }

    public var addPlayerButtonLabel: String {
        switch language {
        case .english:  return "Add player"
        case .french:   return "Ajouter un joueur"
        case .arabic:   return "إضافة لاعب"
        case .spanish:  return "Agregar jugador"
        case .tunisian: return "زود لاعب"
        }
    }

    public var addPlayerHint: String {
        switch language {
        case .english:
            return "Adds the player to the game"
        case .french:
            return "Ajoute le joueur à la partie"
        case .arabic:
            return "إضافة اللاعب إلى اللعبة"
        case .spanish:
            return "Añade el jugador a la partida"
        case .tunisian:
            return "يزيد اللاعب للعبة"
        }
    }

    public func removePlayerLabel(_ playerName: String) -> String {
        switch language {
        case .english:
            return "Remove \(playerName)"
        case .french:
            return "Supprimer \(playerName)"
        case .arabic:
            return "إزالة \(playerName)"
        case .spanish:
            return "Eliminar \(playerName)"
        case .tunisian:
            return "احذف \(playerName)"
        }
    }

    public var removePlayerHint: String {
        switch language {
        case .english:  return "Remove this player from the game"
        case .french:   return "Supprimer ce joueur du jeu"
        case .arabic:   return "إزالة هذا اللاعب من اللعبة"
        case .spanish:  return "Eliminar este jugador del juego"
        case .tunisian: return "احذف هذا اللاعب من اللعبة"
        }
    }

    public var mrWhiteToggleLabel: String {
        switch language {
        case .english:  return "Mr. White Mode"
        case .french:   return "Mode M. Blanc"
        case .arabic:   return "وضع السيد الأبيض"
        case .spanish:  return "Modo Sr. Blanco"
        case .tunisian: return "وضع السيد الأبيض"
        }
    }

    public var mrWhiteToggleHint: String {
        switch language {
        case .english:
            return "Enable or disable Mr. White mode"
        case .french:
            return "Activer ou désactiver le mode Mr. White"
        case .arabic:
            return "تفعيل أو تعطيل وضع السيد الأبيض"
        case .spanish:
            return "Activar o desactivar el modo Sr. White"
        case .tunisian:
            return "فعّل ولا عطّل وضع مستر وايت"
        }
    }

    public var selectTopicHint: String {
        switch language {
        case .english:
            return "Select this topic"
        case .french:
            return "Sélectionner ce thème"
        case .arabic:
            return "اختيار هذا الموضوع"
        case .spanish:
            return "Seleccionar este tema"
        case .tunisian:
            return "اختار الموضوع هذا"
        }
    }

    public var enterVotingHint: String {
        switch language {
        case .english:  return "Start the voting phase to eliminate a player"
        case .french:   return "Commencez la phase de vote pour éliminer un joueur"
        case .arabic:   return "ابدأ مرحلة التصويت لإقصاء لاعب"
        case .spanish:  return "Inicia la fase de votación para eliminar a un jugador"
        case .tunisian: return "ابدا مرحلة التصويت لطرد لاعب"
        }
    }

    public var skipVotingHint: String {
        switch language {
        case .english:  return "Skip voting and continue discussion for another round"
        case .french:   return "Ignorer le vote et continuer la discussion pour un autre tour"
        case .arabic:   return "تجاوز التصويت واستمر في المناقشة لجولة أخرى"
        case .spanish:  return "Omita la votación y continúe la discusión para otra ronda"
        case .tunisian: return "خطي التصويت واستمر النقاش لجولة أخرى"
        }
    }

    public var voteSelectedHint: String {
        switch language {
        case .english:  return "Double tap to change your vote"
        case .french:   return "Double tapez pour changer votre vote"
        case .arabic:   return "انقر مرتين لتغيير تصويتك"
        case .spanish:  return "Doble toque para cambiar tu voto"
        case .tunisian: return "ضغط مزدوج لتغيير تصويتك"
        }
    }

    public var voteSelectHint: String {
        switch language {
        case .english:  return "Double tap to select this player for elimination"
        case .french:   return "Double tapez pour sélectionner ce joueur pour l'élimination"
        case .arabic:   return "انقر مرتين لتحديد هذا اللاعب للإقصاء"
        case .spanish:  return "Doble toque para seleccionar a este jugador para la eliminación"
        case .tunisian: return "ضغط مزدوج لتحديد هذا اللاعب للإقصاء"
        }
    }

    public func confirmVoteHint(_ playerName: String) -> String {
        switch language {
        case .english:
            return "Confirm elimination of \(playerName)?"
        case .french:
            return "Confirmez l'élimination de \(playerName) ?"
        case .arabic:
            return "تأكيد إقصاء \(playerName)؟"
        case .spanish:
            return "¿Confirmar la eliminación de \(playerName)?"
        case .tunisian:
            return "أكد إقصاء \(playerName)؟"
        }
    }

    public var timerHint: String {
        switch language {
        case .english:  return "Time left to discuss and find the undercover player"
        case .french:   return "Temps restant pour discuter et trouver le joueur infiltré"
        case .arabic:   return "وقت متبقي للمناقشة وإيجاد اللاعب السري"
        case .spanish:  return "Tiempo restante para discutir y encontrar al jugador encubierto"
        case .tunisian: return "الوقت الباقي باش تناقشو وتلقاو اللاعب السري"
        }
    }

    // MARK: - Additional Accessibility Strings for Confirmation Overlay
    public var cancel: String {
        switch language {
        case .english:  return "Cancel"
        case .french:   return "Annuler"
        case .arabic:   return "إلغاء"
        case .spanish:  return "Cancelar"
        case .tunisian: return "الغاء"
        }
    }

    public var cancelHint: String {
        switch language {
        case .english:  return "Cancel and return to voting"
        case .french:   return "Annuler et retourner au vote"
        case .arabic:   return "إلغاء والعودة إلى التصويت"
        case .spanish:  return "Cancelar y volver a votar"
        case .tunisian: return "الغاء والرجوع للتصويت"
        }
    }
    
    public var selectLanguageHint: String {
        switch language {
        case .english:
            return "Select this language"
        case .french:
            return "Sélectionner cette langue"
        case .arabic:
            return "اختيار هذه اللغة"
        case .spanish:
            return "Seleccionar este idioma"
        case .tunisian:
            return "اختار اللغة هاذي"
        }
    }
    
    public func confirmEliminationHint(_ name: String) -> String {
        switch language {
        case .english:
            return "Confirm elimination of \(name)"
        case .french:
            return "Confirmer l’élimination de \(name)"
        case .arabic:
            return "تأكيد إقصاء \(name)"
        case .spanish:
            return "Confirmar la eliminación de \(name)"
        case .tunisian:
            return "أكد إقصاء \(name)"
        }
    }
    
    public var selected: String {
        switch language {
        case .english:
            return "Selected"
        case .french:
            return "Sélectionné"
        case .arabic:
            return "محدد"
        case .spanish:
            return "Seleccionado"
        case .tunisian:
            return "محدد"
        }
    }

    public var notSelected: String {
        switch language {
        case .english:
            return "Not selected"
        case .french:
            return "Non sélectionné"
        case .arabic:
            return "غير محدد"
        case .spanish:
            return "No seleccionado"
        case .tunisian:
            return "موش محدد"
        }
    }
    

    public var eliminated: String {
        switch language {
        case .english:
            return "Eliminated"
        case .french:
            return "Éliminé"
        case .arabic:
            return "مُقصى"
        case .spanish:
            return "Eliminado"
        case .tunisian:
            return "مقصي"
        }
    }

    public var active: String {
        switch language {
        case .english:
            return "Active"
        case .french:
            return "Actif"
        case .arabic:
            return "نشط"
        case .spanish:
            return "Activo"
        case .tunisian:
            return "ناشط"
        }
    }
    
    public var startGameHint: String {
        switch language {
        case .english:
            return "Starts the game"
        case .french:
            return "Commence la partie"
        case .arabic:
            return "بدء اللعبة"
        case .spanish:
            return "Comienza la partida"
        case .tunisian:
            return "باش تبدا اللعبة"
        }
    }
    
    public func playerCount(_ count: Int) -> String {
        switch language {
        case .english:
            return "\(count) of 10 players"
        case .french:
            return "\(count) joueurs sur 10"
        case .arabic:
            return "\(count) من 10 لاعبين"
        case .spanish:
            return "\(count) de 10 jugadores"
        case .tunisian:
            return "\(count) من 10 لاعبين"
        }
    }
    
    public var selectDifficultyHint: String {
        switch language {
        case .english:
            return "Select this difficulty"
        case .french:
            return "Sélectionner cette difficulté"
        case .arabic:
            return "اختيار هذه الصعوبة"
        case .spanish:
            return "Seleccionar esta dificultad"
        case .tunisian:
            return "اختار الصعوبة هاذي"
        }
    }
    
    public func timerAccessibilityLabel(_ seconds: Int) -> String {
        switch language {
        case .english:
            return "\(seconds) seconds remaining"
        case .french:
            return "\(seconds) secondes restantes"
        case .arabic:
            return "تبقى \(seconds) ثانية"
        case .spanish:
            return "Quedan \(seconds) segundos"
        case .tunisian:
            return "باقي \(seconds) ثانية"
        }
    }
    
    public var skipVote: String {
        switch language {
        case .english:
            return "Skip vote"
        case .french:
            return "Passer le vote"
        case .arabic:
            return "تخطي التصويت"
        case .spanish:
            return "Saltar la votación"
        case .tunisian:
            return "عدّي التصويت"
        }
    }
    
    public var eliminate: String {
        switch language {
        case .english:
            return "ELIMINATE"
        case .french:
            return "ÉLIMINER"
        case .arabic:
            return "إقصاء"
        case .spanish:
            return "ELIMINAR"
        case .tunisian:
            return "إقصاء"
        }
    }
    
    public var eliminationConfirmation: String {
        switch language {
        case .english:
            return "Are you sure? This cannot be undone."
        case .french:
            return "Êtes-vous sûr ? Cette action est irréversible."
        case .arabic:
            return "هل أنت متأكد؟ لا يمكن التراجع عن هذا."
        case .spanish:
            return "¿Estás seguro? Esta acción no se puede deshacer."
        case .tunisian:
            return "متأكد؟ ما تنجمش ترجع في القرار هذا."
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

    public var finalGuess: String {
        switch language {
        case .english:  return "Final Guess"
        case .french:   return "Dernière tentative"
        case .arabic:   return "التخمين الأخير"
        case .spanish:  return "Último intento"
        case .tunisian: return "آخر تخمينة"
        }
    }

    public var oneLastChance: String {
        switch language {
        case .english:  return "One Last Chance"
        case .french:   return "Une dernière chance"
        case .arabic:   return "فرصة أخيرة"
        case .spanish:  return "Una última oportunidad"
        case .tunisian: return "آخر فرصة"
        }
    }

    public var guessCiviliansWord: String {
        switch language {
        case .english:
            return "Guess the civilians' word to win."
        case .french:
            return "Trouvez le mot des civils pour gagner."
        case .arabic:
            return "خمن كلمة المدنيين للفوز."
        case .spanish:
            return "Adivina la palabra de los civiles para ganar."
        case .tunisian:
            return "خمّن كلمة المدنيين باش تربح."
        }
    }

    public var didMrWhiteGuessIt: String {
        switch language {
        case .english:  return "Did Mr. White guess it?"
        case .french:   return "Mr. White a-t-il trouvé ?"
        case .arabic:   return "هل خمن السيد الأبيض الكلمة؟"
        case .spanish:  return "¿Adivinó Sr. White?"
        case .tunisian: return "مستر وايت خمّنها؟"
        }
    }

    public var sayGuessThenConfirm: String {
        switch language {
        case .english:
            return "Say the guess out loud, then confirm the result."
        case .french:
            return "Dites votre réponse à voix haute, puis confirmez le résultat."
        case .arabic:
            return "قل التخمين بصوت عالٍ، ثم أكد النتيجة."
        case .spanish:
            return "Di la respuesta en voz alta y confirma el resultado."
        case .tunisian:
            return "قول التخمين بصوت عالي، وبعد أكد النتيجة."
        }
    }

    public var spokenGuess: String {
        switch language {
        case .english:  return "SPOKEN GUESS"
        case .french:   return "RÉPONSE ORALE"
        case .arabic:   return "التخمين المنطوق"
        case .spanish:  return "RESPUESTA ORAL"
        case .tunisian: return "التخمين بالصوت"
        }
    }

    public var gotIt: String {
        switch language {
        case .english:  return "GOT IT"
        case .french:   return "TROUVÉ"
        case .arabic:   return "صحيح"
        case .spanish:  return "ACERTÓ"
        case .tunisian: return "صحيحة"
        }
    }

    public var wrong: String {
        switch language {
        case .english:  return "WRONG"
        case .french:   return "FAUX"
        case .arabic:   return "خطأ"
        case .spanish:  return "INCORRECTO"
        case .tunisian: return "غلط"
        }
    }

    public var orTypeTheGuess: String {
        switch language {
        case .english:  return "OR TYPE THE GUESS"
        case .french:   return "OU ÉCRIVEZ LA RÉPONSE"
        case .arabic:   return "أو اكتب التخمين"
        case .spanish:  return "O ESCRIBE LA RESPUESTA"
        case .tunisian: return "ولا اكتب التخمين"
        }
    }

    public var typeTheWord: String {
        switch language {
        case .english:  return "Type the word…"
        case .french:   return "Écrivez le mot…"
        case .arabic:   return "اكتب الكلمة…"
        case .spanish:  return "Escribe la palabra…"
        case .tunisian: return "اكتب الكلمة…"
        }
    }

    public var checkGuess: String {
        switch language {
        case .english:  return "CHECK GUESS"
        case .french:   return "VÉRIFIER"
        case .arabic:   return "تحقق من التخمين"
        case .spanish:  return "COMPROBAR"
        case .tunisian: return "ثبّت التخمين"
        }
    }

    public var checking: String {
        switch language {
        case .english:  return "CHECKING…"
        case .french:   return "VÉRIFICATION…"
        case .arabic:   return "جارٍ التحقق…"
        case .spanish:  return "COMPROBANDO…"
        case .tunisian: return "نتثبت…"
        }
    }

    public var selectCorrectGuessHint: String {
        switch language {
        case .english:
            return "Mark the spoken guess as correct"
        case .french:
            return "Marquer la réponse orale comme correcte"
        case .arabic:
            return "تحديد التخمين المنطوق كإجابة صحيحة"
        case .spanish:
            return "Marcar la respuesta oral como correcta"
        case .tunisian:
            return "اعتبر التخمين بالصوت صحيح"
        }
    }

    public var selectWrongGuessHint: String {
        switch language {
        case .english:
            return "Mark the spoken guess as incorrect"
        case .french:
            return "Marquer la réponse orale comme incorrecte"
        case .arabic:
            return "تحديد التخمين المنطوق كإجابة خاطئة"
        case .spanish:
            return "Marcar la respuesta oral como incorrecta"
        case .tunisian:
            return "اعتبر التخمين بالصوت غلط"
        }
    }

    public var guessInputLabel: String {
        switch language {
        case .english:  return "Your guess"
        case .french:   return "Votre réponse"
        case .arabic:   return "تخمينك"
        case .spanish:  return "Tu respuesta"
        case .tunisian: return "تخمينك"
        }
    }

    public func countdownAccessibilityLabel(_ seconds: Int) -> String {
        switch language {
        case .english:
            return "\(seconds) seconds"
        case .french:
            return "\(seconds) secondes"
        case .arabic:
            return "\(seconds) ثوانٍ"
        case .spanish:
            return "\(seconds) segundos"
        case .tunisian:
            return "\(seconds) ثواني"
        }
    }
    
    // MARK: - Reveal View access
    
    public var reveal: String {
        switch language {
        case .english:  return "Reveal"
        case .french:   return "Révéler"
        case .arabic:   return "كشف"
        case .spanish:  return "Revelar"
        case .tunisian: return "كشف"
        }
    }

    public func revealProgress(_ current: Int, _ total: Int) -> String {
        switch language {
        case .english:
            return "Reveal, player \(current) of \(total)"
        case .french:
            return "Révélation, joueur \(current) sur \(total)"
        case .arabic:
            return "كشف، اللاعب \(current) من \(total)"
        case .spanish:
            return "Revelación, jugador \(current) de \(total)"
        case .tunisian:
            return "الكشف، اللاعب \(current) من \(total)"
        }
    }

    public var passDevice: String {
        switch language {
        case .english:  return "Pass the device"
        case .french:   return "Passez l'appareil"
        case .arabic:   return "مرر الجهاز"
        case .spanish:  return "Pasa el dispositivo"
        case .tunisian: return "عدّي التليفون"
        }
    }

    public var onlyYouShouldSeeYourWord: String {
        switch language {
        case .english:
            return "Only you should see your word."
        case .french:
            return "Vous seul devez voir votre mot."
        case .arabic:
            return "فقط أنت يجب أن ترى كلمتك."
        case .spanish:
            return "Solo tú debes ver tu palabra."
        case .tunisian:
            return "كان إنت تشوف كلمتك."
        }
    }

    public var revealMyWord: String {
        switch language {
        case .english:  return "Reveal my word"
        case .french:   return "Révéler mon mot"
        case .arabic:   return "اكشف كلمتي"
        case .spanish:  return "Revelar mi palabra"
        case .tunisian: return "اكشف كلمتي"
        }
    }

    public var yourWord: String {
        switch language {
        case .english:  return "Your word"
        case .french:   return "Votre mot"
        case .arabic:   return "كلمتك"
        case .spanish:  return "Tu palabra"
        case .tunisian: return "كلمتك"
        }
    }

    public func yourWordIs(_ word: String) -> String {
        switch language {
        case .english:
            return "Your word: \(word)"
        case .french:
            return "Votre mot : \(word)"
        case .arabic:
            return "كلمتك: \(word)"
        case .spanish:
            return "Tu palabra: \(word)"
        case .tunisian:
            return "كلمتك: \(word)"
        }
    }

    public var mrWhiteNoWord: String {
        switch language {
        case .english:
            return "Mr. White. No word. Bluff your way through."
        case .french:
            return "Mr. White. Aucun mot. Bluffez pour vous en sortir."
        case .arabic:
            return "السيد الأبيض. لا توجد كلمة. حاول خداع الآخرين."
        case .spanish:
            return "Sr. White. No tienes palabra. Engaña a los demás."
        case .tunisian:
            return "مستر وايت. ما عندكش كلمة. حاول تبلّف."
        }
    }

    public var hideAndPass: String {
        switch language {
        case .english:  return "Hide and pass"
        case .french:   return "Cacher et passer"
        case .arabic:   return "أخفِ وأعطِ"
        case .spanish:  return "Ocultar y pasar"
        case .tunisian: return "خبّي وعدّي"
        }
    }
    
    public var shownUpsideDownForPrivacy: String {
        switch language {
        case .english:
            return "Shown upside-down for privacy. Rotate the device to read."
        case .french:
            return "Affiché à l'envers pour préserver la confidentialité. Tournez l'appareil pour lire."
        case .arabic:
            return "تظهر الكلمة مقلوبة للخصوصية. اعكس الجهاز لقراءتها."
        case .spanish:
            return "Se muestra al revés por privacidad. Gira el dispositivo para leer."
        case .tunisian:
            return "الكلمة مقلوبة للخصوصية. اعكس الجهاز باش تقراها."
        }
    }
    
    public var mrWhiteBluffMessage: String {
        switch language {
        case .english:
            return "No word.\nBluff your way through."
        case .french:
            return "Aucun mot.\nBluffez pour vous en sortir."
        case .arabic:
            return "لا توجد كلمة.\nيجب أن تخدع الآخرين."
        case .spanish:
            return "Sin palabra.\nEngaña a los demás."
        case .tunisian:
            return "ما عندكش كلمة.\nبلّف باش تكمل."
        }
    }
    
    public var tapToReveal: String {
        switch language {
        case .english:  return "TAP TO REVEAL"
        case .french:   return "APPUYEZ POUR RÉVÉLER"
        case .arabic:   return "اضغط للكشف"
        case .spanish:  return "TOCA PARA REVELAR"
        case .tunisian: return "إضغط باش تكشف"
        }
    }
    
    public var mrWhiteWas: String {
        switch language {
        case .english:  return "MR. WHITE WAS"
        case .french:   return "MR. WHITE ÉTAIT"
        case .arabic:   return "السيد الأبيض كان"
        case .spanish:  return "EL SR. WHITE ERA"
        case .tunisian: return "مستر وايت كان"
        }
    }
    
    // MARK: - Home

    public var appTitle: String {
        switch language {
        case .english:
            return "UNDERCOVER"
        case .french:
            return "UNDERCOVER"
        case .arabic:
            return "UNDERCOVER"
        case .spanish:
            return "UNDERCOVER"
        case .tunisian:
            return "UNDERCOVER"
        }
    }

    public var tagline: String {
        switch language {
        case .english:
            return "Blend in. Or get caught."
        case .french:
            return "Fondez-vous dans le groupe. Ou soyez démasqué."
        case .arabic:
            return "اندمج مع الآخرين. أو انكشف."
        case .spanish:
            return "Mézclate. O queda al descubierto."
        case .tunisian:
            return "إندمج. ولا تتكشف"
        }
    }

    public var play: String {
        switch language {
        case .english:
            return "Play"
        case .french:
            return "Jouer"
        case .arabic:
            return "العب"
        case .spanish:
            return "Jugar"
        case .tunisian:
            return "إلعب"
        }
    }

    public var minimumPlayersRequired: String {
        switch language {
        case .english:
            return "3 or more players required"
        case .french:
            return "3 joueurs ou plus sont nécessaires"
        case .arabic:
            return "يلزم 3 لاعبين أو أكثر"
        case .spanish:
            return "Se necesitan 3 jugadores o más"
        case .tunisian:
            return "يلزم 3 لاعبين ولا أكثر"
        }
    }
    
    // MARK: - Results

    public func resultTitle(for result: GameResult) -> String {
        switch language {
        case .english:
            switch result {
            case .civiliansWin:
                return "Civilians Win!"
            case .undercoverWins:
                return "Undercover Wins!"
            case .mrWhiteWins:
                return "Mr. White Wins!"
            }

        case .french:
            switch result {
            case .civiliansWin:
                return "Les civils gagnent !"
            case .undercoverWins:
                return "L'Undercover gagne !"
            case .mrWhiteWins:
                return "Mr. White gagne !"
            }

        case .arabic:
            switch result {
            case .civiliansWin:
                return "المدنيون يفوزون!"
            case .undercoverWins:
                return "المتخفي يفوز!"
            case .mrWhiteWins:
                return "مستر وايت يفوز!"
            }

        case .spanish:
            switch result {
            case .civiliansWin:
                return "¡Los civiles ganan!"
            case .undercoverWins:
                return "¡El infiltrado gana!"
            case .mrWhiteWins:
                return "¡Mr. White gana!"
            }

        case .tunisian:
            switch result {
            case .civiliansWin:
                return "المدنيين ربحوا!"
            case .undercoverWins:
                return "الـUndercover ربح!"
            case .mrWhiteWins:
                return "مستر وايت ربح!"
            }
        }
    }
}
