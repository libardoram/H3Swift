# H3Swift

A Swift package providing an idiomatic Swift API for [Uber's H3](https://h3geo.org/) hexagonal geospatial indexing system.

H3 divides the Earth's surface into a hierarchical grid of hexagonal cells, each identified by a 64-bit integer. This library wraps the underlying C library (via [Ch3](https://github.com/bdotdub/Ch3)) and exposes a clean, type-safe Swift interface.

## Requirements

- Swift 5.10+
- iOS 14+ / macOS 11+ / watchOS 7+ / tvOS 14+

## Installation

### Swift Package Manager

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/<your-username>/H3Swift.git", from: "1.0.0"),
]
```

Then add `"H3"` to your target's dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: ["H3"]
)
```

### Xcode

1. **File** → **Add Package Dependencies…**
2. Enter the repository URL.
3. Choose the version rule and click **Add Package**.

## Usage

### Convert a coordinate to an H3 index

```swift
import H3

let coord = H3Coordinate(lat: 37.7793, lon: -122.4193)
let index = H3Index(coordinate: coord, resolution: 9)

print(index)          // e.g. "8928308280fffff"
print(index.isValid)  // true
print(index.resolution) // 9
```

### Create an index from a hex string

```swift
// Failable — returns nil for invalid strings
if let index = H3Index(string: "8928308280fffff") {
    print(index.coordinate) // center of the cell
}
```

### Traverse neighbors (k-ring)

```swift
let neighbors = index.kRing(k: 1)  // 7 cells: self + 6 neighbors
let twoRings  = index.kRing(k: 2)  // 19 cells
```

### Navigate the hierarchy

```swift
// Coarser resolution
let parent = index.parent(at: 5)
let directParent = index.directParent

// Finer resolution
let children = index.children(at: 10)
let centerChild = index.directCenterChild
```

### Get the cell boundary

```swift
let vertices = index.boundary()  // [H3Coordinate] in CCW order
```

### Grid distance between two cells

How many cells apart are two H3 indexes at the same resolution?

```swift
import H3
import Ch3

let sf    = H3Index(coordinate: H3Coordinate(lat: 37.7793, lon: -122.4193), resolution: 9)
let oakland = H3Index(coordinate: H3Coordinate(lat: 37.8044, lon: -122.2712), resolution: 9)

let steps = h3Distance(sf.rawValue, oakland.rawValue)
print(steps)  // e.g. 42  (grid hops, not kilometres)
```

### Check if a cell is a pentagon

The H3 grid contains 12 pentagons per resolution (at icosahedron vertices). Most spatial operations work fine on them, but it's useful to know:

```swift
import H3
import Ch3

let coord = H3Coordinate(lat: 37.7793, lon: -122.4193)
let index = H3Index(coordinate: coord, resolution: 5)

if h3IsPentagon(index.rawValue) == 1 {
    print("\(index) is a pentagon")
} else {
    print("\(index) is a hexagon")
}

// Get all 12 pentagons at resolution 3
var pentagons = [UInt64](repeating: 0, count: Int(pentagonIndexCount()))
getPentagonIndexes(3, &pentagons)
let pentagonIndexes = pentagons.map { H3Index($0) }
```

### Average cell area and edge length at a resolution

Useful for understanding the scale of your data:

```swift
import Ch3

for res in 0...5 {
    let areKm2   = hexAreaKm2(Int32(res))
    let edgeKm   = edgeLengthKm(Int32(res))
    let count    = numHexagons(Int32(res))
    print("res \(res): \(areKm2) km²  edge \(edgeKm) km  total cells \(count)")
}
// res 0:  4357449.4 km²  edge 1107.7 km  total cells 122
// res 1:   609788.4 km²  edge  418.7 km  total cells 842
// res 2:    86745.9 km²  edge  158.2 km  total cells 5882
// ...
```

## API Reference

### `H3Coordinate`

| Property / Initializer | Description |
|---|---|
| `init(lat:lon:)` | Creates a coordinate from degrees |
| `lat: Double` | Latitude in degrees |
| `lon: Double` | Longitude in degrees |

Conforms to `Equatable`, `Hashable`, `Codable`, `Sendable`.

### `H3Index`

| Initializer | Description |
|---|---|
| `init(_ value: UInt64)` | Wrap a raw 64-bit index |
| `init(coordinate:resolution:)` | Convert a coordinate to an H3 cell |
| `init?(string:)` | Parse a hex string; returns `nil` if invalid |

| Property | Description |
|---|---|
| `rawValue: UInt64` | The underlying 64-bit value |
| `resolution: Int` | Resolution (0–15) |
| `isValid: Bool` | Whether this is a valid H3 index |
| `coordinate: H3Coordinate` | Center coordinate of the cell |
| `description: String` | Lowercase hex string (e.g. `"8928308280fffff"`) |
| `directParent: H3Index?` | Parent one resolution coarser |
| `directCenterChild: H3Index?` | Center child one resolution finer |

| Method | Description |
|---|---|
| `kRing(k:)` | All cells within `k` rings |
| `parent(at:)` | Ancestor at the given resolution |
| `children(at:)` | All children at the given resolution |
| `centerChild(at:)` | Center child at the given resolution |
| `boundary()` | Cell boundary vertices |

Conforms to `Equatable`, `Hashable`, `CustomStringConvertible`, `Sendable`.

## License

MIT License. See [LICENSE](LICENSE) for details.
