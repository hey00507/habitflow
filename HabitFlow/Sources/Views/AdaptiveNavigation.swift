import SwiftUI

/// macOS에서는 NavigationSplitView가 이미 네비게이션을 제공하므로
/// 내부 뷰에서 NavigationStack을 중복 감싸지 않는다.
/// iOS에서는 NavigationStack으로 감싼다.
struct AdaptiveNavigation<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        #if os(macOS)
        content()
        #else
        NavigationStack {
            content()
        }
        #endif
    }
}

extension View {
    /// macOS에서 sheet 최소 크기를 확보한다.
    func adaptiveSheet() -> some View {
        #if os(macOS)
        self.frame(minWidth: 480, minHeight: 500)
        #else
        self
        #endif
    }
}
