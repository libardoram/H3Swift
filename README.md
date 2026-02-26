# H3Swift

[![Swift](https://img.shields.io/badge/swift-5.10-blue)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-blue)](https://swift.org)
[![SPM](https://img.shields.io/badge/swift%20package%20manager-swiftpm-blue)](https://swift.org/package-manager/)

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
    .package(url: "https://github.com/libardoram/H3Swift.git", from: "1.0.0"),
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

let coord = H3Coordinate(lat: 37.7793, lng: -122.4193)
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

### Get the cell edges

```swift
let edges = index.edges()  // 6 edges for hexagon, 5 for pentagon

for edge in edges {
    print("Edge: \(edge)")
    print("Origin: \(edge.origin)")
    print("Destination: \(edge.destination)")
    print("Boundary: \(edge.boundary())")
}

// Create edge between two neighboring cells
let neighbor = index.kRing(k: 1).first { $0 != index }!
if let edge = H3Edge(from: index, to: neighbor) {
    print("Created edge: \(edge)")
}
```

### Grid distance between two cells

How many cells apart are two H3 indexes at the same resolution?

```swift
import H3

let sf    = H3Index(coordinate: H3Coordinate(lat: 37.7793, lng: -122.4193), resolution: 9)
let oakland = H3Index(coordinate: H3Coordinate(lat: 37.8044, lng: -122.2712), resolution: 9)

let steps = sf.distance(to: oakland)
print(steps)  // e.g. 42  (grid hops, not kilometres)
```

### Check if a cell is a pentagon

The H3 grid contains 12 pentagons per resolution (at icosahedron vertices). Most spatial operations work fine on them, but it's useful to know:

```swift
import H3

let coord = H3Coordinate(lat: 37.7793, lng: -122.4193)
let index = H3Index(coordinate: coord, resolution: 5)

if index.isPentagon {
    print("\(index) is a pentagon")
} else {
    print("\(index) is a hexagon")
}

// Get all 12 pentagons at resolution 3
let pentagonIndexes = H3Index.pentagons(resolution: 3)
```

### Average cell area and edge length at a resolution

Useful for understanding the scale of your data:

```swift
import H3

for res in 0...5 {
    let areaKm2 = H3Index.hexArea(resolution: res, unit: .km2)
    let edgeKm  = H3Index.edgeLength(resolution: res, unit: .km)
    let count   = H3Index.cellCount(resolution: res)
    print("res \(res): \(areaKm2) km²  edge \(edgeKm) km  total cells \(count)")
}
// res 0:  4357449.4 km²  edge 1107.7 km  total cells 122
// res 1:   609788.4 km²  edge  418.7 km  total cells 842
// res 2:    86745.9 km²  edge  158.2 km  total cells 5882
// ...
```

### Fill a polygon with H3 cells

Convert a geographic polygon into a set of H3 cells at a given resolution:

```swift
import H3

let exterior: [H3Coordinate] = [
    H3Coordinate(lat: 37.7749, lng: -122.4194),
    H3Coordinate(lat: 37.8049, lng: -122.4194),
    H3Coordinate(lat: 37.8049, lng: -122.3894),
    H3Coordinate(lat: 37.7749, lng: -122.3894),
]

let polygon = H3GeoPolygon(exterior: exterior)
let cells = polygon.fill(resolution: 9)

print("Filled \(cells.count) cells")

// With holes
let hole: [H3Coordinate] = [
    H3Coordinate(lat: 37.7849, lng: -122.4144),
    H3Coordinate(lat: 37.7949, lng: -122.4144),
    H3Coordinate(lat: 37.7949, lng: -122.4044),
    H3Coordinate(lat: 37.7849, lng: -122.4044),
]
let polygonWithHole = H3GeoPolygon(exterior: exterior, holes: [hole])
let cellsWithHole = polygonWithHole.fill(resolution: 9)
```

## Examples

The repository includes two example scripts demonstrating package functionality:

### Running Examples

```bash
# Run basic example
swift Examples/BasicExample.swift

# Run advanced example
swift Examples/AdvancedExample.swift
```

### Basic Example (`Examples/BasicExample.swift`)

Demonstrates core functionality:
- Convert coordinates to H3 indexes
- Get cell center and boundary
- Traverse neighbors (k-ring)
- Navigate hierarchy (parent/children)
- Check cell properties (pentagon, base cell, resolution class)
- Query resolution statistics
- Get pentagons and resolution-0 cells

### Advanced Example (`Examples/AdvancedExample.swift`)

Demonstrates advanced functionality:
- Grid distance between locations
- Grid line between cells
- Neighbor detection
- Cell edges (create and query)
- Polyfill (polygon to H3 cells)
- Polyfill with holes
- Compact/uncompact cells
- kRingDistances
- HexRing
- Icosahedron faces

## API Reference

### `H3Coordinate`

| Property / Initializer | Description |
|---|---|
| `init(lat:lng:)` | Creates a coordinate from degrees |
| `lat: Double` | Latitude in degrees |
| `lng: Double` | Longitude in degrees |

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
| `baseCell: Int` | Base cell number (0–121) |
| `isPentagon: Bool` | Whether this cell is one of the 12 pentagons |
| `isResClassIII: Bool` | Whether at a Class III resolution (odd resolutions) |
| `directParent: H3Index?` | Parent one resolution coarser |
| `directCenterChild: H3Index?` | Center child one resolution finer |

| Method | Description |
|---|---|
| `kRing(k:)` | All cells within `k` rings |
| `kRingDistances(k:)` | All cells within `k` rings with grid distances |
| `hexRing(k:)` | Cells in the hollow ring at exactly distance `k` |
| `parent(at:)` | Ancestor at the given resolution |
| `children(at:)` | All children at the given resolution |
| `centerChild(at:)` | Center child at the given resolution |
| `distance(to:)` | Grid distance to another cell |
| `gridLine(to:)` | Grid line to another cell |
| `isNeighbor(of:)` | Whether another cell is a direct neighbor |
| `edges()` | All unidirectional edges originating from this cell |
| `faces()` | Icosahedron face numbers this cell intersects |
| `boundary()` | Cell boundary vertices |
| `compact(_:)` | Compress cells to most coarse resolution |
| `uncompact(_:resolution:)` | Expand compacted cells to target resolution |
| `hexArea(resolution:unit:)` | Average cell area at resolution |
| `edgeLength(resolution:unit:)` | Average edge length at resolution |
| `cellCount(resolution:)` | Total cells at resolution |
| `res0Cells()` | All 122 resolution-0 base cells |
| `pentagons(resolution:)` | All 12 pentagons at resolution |

Conforms to `Equatable`, `Hashable`, `CustomStringConvertible`, `Sendable`.

### `H3Edge`

Represents a unidirectional edge between two neighboring H3 cells.

| Initializer | Description |
|---|---|
| `init(_ value: UInt64)` | Wrap a raw 64-bit edge index |
| `init?(from:to:)` | Create edge between two neighboring cells |

| Property | Description |
|---|---|
| `rawValue: UInt64` | The underlying 64-bit value |
| `isValid: Bool` | Whether this is a valid directed edge |
| `origin: H3Index` | The origin cell |
| `destination: H3Index` | The destination cell |
| `cells: (origin: H3Index, destination: H3Index)` | Both cells |

| Method | Description |
|---|---|
| `boundary()` | Edge boundary vertices |

Conforms to `Equatable`, `Hashable`, `CustomStringConvertible`, `Sendable`.

### `H3GeoPolygon`

A geographic polygon for polyfill operations.

| Initializer | Description |
|---|---|
| `init(exterior:holes:)` | Create polygon with exterior and optional holes |

| Property | Description |
|---|---|
| `exterior: [H3Coordinate]` | The exterior boundary |
| `holes: [[H3Coordinate]]` | Interior holes |

| Method | Description |
|---|---|
| `fill(resolution:)` | Get all H3 cells within the polygon |

Conforms to `Sendable`.

### Supporting Types

| Type | Description |
|---|---|
| `H3Index.AreaUnit` | `.km2` or `.m2` for area queries |
| `H3Index.LengthUnit` | `.km` or `.m` for length queries |
| `H3Index.KRingEntry` | Pairs `index: H3Index` with `distance: Int` |

## License

MIT License. See [LICENSE](LICENSE) for details.
