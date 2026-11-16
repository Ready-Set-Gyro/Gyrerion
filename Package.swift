// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StrideMetrics",
    products: [
        .library(name: "StrideMetrics", targets: ["StrideMetrics"]),
    ],
    targets: [
        .target(name: "StrideMetrics"),
        .testTarget(name: "StrideMetricsTests", dependencies: ["StrideMetrics"]),
    ]
)
