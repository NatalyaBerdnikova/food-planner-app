//
//  ContentView.swift
//  food-planner
//
//  Created by Наталья Бердникова on 15.05.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var meals = ["Овсянка", "Суп", "Салат"]

    var body: some View {
        VStack(spacing: 16) {
            Text("Меню")
                .font(.title)

            List {
                ForEach(meals, id: \.self) { meal in
                    Text(meal)
                }
                .onDelete(perform: deleteMeals)
            }
            .listStyle(.insetGrouped)

            Button("Добавить блюдо") {
                meals.append("Блюдо \(meals.count + 1)")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func deleteMeals(at offsets: IndexSet) {
        meals.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
