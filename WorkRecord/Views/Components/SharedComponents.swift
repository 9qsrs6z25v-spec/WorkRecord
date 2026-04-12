import SwiftUI

// MARK: - Card View
struct CardView<Content: View>: View {
    var background: Color = AppTheme.card
    var borderColor: Color = AppTheme.border
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(18)
        .background(background)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }
}

// MARK: - Section Title
struct SectionTitle: View {
    let icon: String
    let title: String
    var subtitle: String = ""

    var body: some View {
        HStack(alignment: .center) {
            Text("\(icon) \(title)")
                .font(.system(size: 19, weight: .black))
                .kerning(2)
            if !subtitle.isEmpty {
                Spacer()
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.muted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .overlay(
            Rectangle().fill(AppTheme.border).frame(height: 1.5),
            alignment: .bottom
        )
        .padding(.bottom, 18)
    }
}

// MARK: - Card Title
struct CardTitle: View {
    let icon: String
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            Text("\(icon) \(title)")
                .font(.system(size: 13, weight: .bold))
                .kerning(0.5)
            Spacer()
            if let trailing = trailing {
                trailing
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let label: String
    let value: String
    let unit: String
    var color: Color = AppTheme.ink
    var bgColor: Color = AppTheme.card
    var borderColor: Color = AppTheme.border

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(AppTheme.muted)
                .kerning(1.5)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 17, weight: .black))
                .foregroundColor(color)
            Text(unit)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(bgColor)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1))
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let text: String
    let style: BadgeStyle

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(style.fg)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(style.bg)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(style.border, lineWidth: 1))
    }
}

// MARK: - Quick Date Button
struct QuickDateButton: View {
    let label: String
    let isSelected: Bool
    var isSpecial: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(
                    isSelected ? (isSpecial ? .white : AppTheme.ink) :
                    (isSpecial ? Color(hex: "a371f7") : .white.opacity(0.55))
                )
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .background(
                    isSelected ? (isSpecial ? Color(hex: "a371f7") : AppTheme.gold) :
                    Color.white.opacity(0.06)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20).stroke(
                        isSelected ? (isSpecial ? Color(hex: "a371f7") : AppTheme.gold) :
                        (isSpecial ? Color(hex: "a371f7").opacity(0.4) : Color.white.opacity(0.15)),
                        lineWidth: 1
                    )
                )
        }
    }
}

// MARK: - Form Field
struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(AppTheme.muted)
                .kerning(1.5)
                .textCase(.uppercase)
            content()
        }
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .kerning(1)
                .foregroundColor(AppTheme.gold2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(AppTheme.ink)
                .cornerRadius(8)
        }
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .kerning(1)
                .foregroundColor(AppTheme.muted)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(AppTheme.paper)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
        }
    }
}

// MARK: - Small Action Button
struct SmallActionButton: View {
    let title: String
    var color: Color = AppTheme.blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(color)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 26))
                .opacity(0.45)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
    }
}

// MARK: - Toast Overlay
struct ToastModifier: ViewModifier {
    @Binding var message: String
    @Binding var isShowing: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.gold2)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppTheme.ink)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                        .transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.3), value: isShowing)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isShowing = false
                    }
                }
            }
        }
    }
}
