import Foundation

enum FoodCatalogAliases {
    static let replacements: [String: String] = [
        "abrikosy": "apricots",
        "batat_kartofel_sladkiy": "batata_sweet_potatoes",
        "chia_seeds": "semena_chia_sushenye",
        "courgette": "zucchini",
        "cranberries": "cranberry",
        "cream_cheese_light_18_fat": "light_cream_cheese",
        "cumin": "ground_cumin",
        "honey": "bee_honey",
        "item_5": "black_currant",
        "kalmar": "squid",
        "karri_poroshok": "curry_spice",
        "oregano": "oregano_sushenyy",
        "parsley": "fresh_parsley",
        "perets_chernyy_molotyy_ili_goroshek": "black_pepper",
        "poult": "chicken",
        "pshenichnaya_muka_vysshego_sorta": "wheat_flour_premium_grade",
        "sesame_seeds_and": "sesame_seeds",
    ]

    static func canonicalKey(for catalogKey: String) -> String {
        replacements[catalogKey] ?? catalogKey
    }

    static func isCanonical(_ catalogKey: String) -> Bool {
        replacements[catalogKey] == nil
    }
}
