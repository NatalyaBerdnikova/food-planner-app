import Foundation

enum FoodCatalogAliases {
    static let replacements: [String: String] = [
        "abrikosy": "apricots",
        "batat_kartofel_sladkiy": "batata_sweet_potatoes",
        "carp_2": "carp",
        "chia_seeds": "semena_chia_sushenye",
        "courgette": "zucchini",
        "cranberries": "cranberry",
        "cream_cheese_light_18_fat": "light_cream_cheese",
        "cumin": "zira_semena",
        "honey": "bee_honey",
        "kalmar": "squid",
        "karri_poroshok": "curry_spice",
        "ogurets_marinovannyy_produkt_udalen": "pickled_cucumber",
        "oregano": "oregano_sushenyy",
        "parsley": "fresh_parsley",
        "perets_chernyy_molotyy_ili_goroshek": "black_pepper",
        "pshenichnaya_muka_vysshego_sorta": "wheat_flour_premium_grade",
    ]

    static func canonicalKey(for catalogKey: String) -> String {
        replacements[catalogKey] ?? catalogKey
    }

    static func isCanonical(_ catalogKey: String) -> Bool {
        replacements[catalogKey] == nil
    }
}
