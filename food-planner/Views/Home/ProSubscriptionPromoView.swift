import SwiftUI
import UIKit

struct ProSubscriptionPromoView: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("home.proPromo.title")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color(red: 0.92, green: 0.86, blue: 0.64))
                    Text("home.proPromo.subtitle")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(2)
                    Text("home.proPromo.cta")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(red: 0.22, green: 0.18, blue: 0.05))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.90, green: 0.76, blue: 0.43), in: Capsule())
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            .background {
                PromoBackgroundImage()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("home.proPromo.accessibility")
    }
}

struct ProSubscriptionOfferSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PromoBackgroundImage()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(alignment: .bottomLeading) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("home.proOffer.bannerTitle")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.white)
                                    Text("home.proOffer.bannerSubtitle")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                .padding(14)
                            }
                        }

                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(icon: "wand.and.stars", text: "home.proOffer.feature.ai")
                        featureRow(icon: "chart.line.uptrend.xyaxis", text: "home.proOffer.feature.insights")
                        featureRow(icon: "calendar.badge.clock", text: "home.proOffer.feature.plan")
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("home.proOffer.price")
                            .font(.title3.weight(.bold))
                        Text("home.proOffer.priceHint")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("home.proOffer.primaryAction")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.06, green: 0.33, blue: 0.45))

                    Button("common.cancel") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("home.proOffer.navTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func featureRow(icon: String, text: LocalizedStringResource) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color(red: 0.06, green: 0.33, blue: 0.45))
                .frame(width: 26, height: 26)
                .background(Color(red: 0.06, green: 0.33, blue: 0.45).opacity(0.12), in: Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PromoBackgroundImage: View {
    private var bundledImage: UIImage? {
        if let image = UIImage(named: "Background") {
            return image
        }
        if let image = UIImage(named: "PromoMaterials/Background") {
            return image
        }
        if let url = Bundle.main.url(forResource: "Background", withExtension: "jpg", subdirectory: "PromoMaterials"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        if let url = Bundle.main.url(forResource: "Background", withExtension: "jpg"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return nil
    }

    var body: some View {
        Group {
            if let image = bundledImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.14, anchor: .trailing)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .offset(x: 8)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.22, blue: 0.28),
                        Color(red: 0.05, green: 0.12, blue: 0.18),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .overlay {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.20),
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.34),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipped()
    }
}
