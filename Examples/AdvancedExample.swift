import H3

print("=== H3 Advanced Examples ===\n")

print("1. Grid distance between two locations")
let sf = H3Coordinate(lat: 37.7749, lng: -122.4194)
let oakland = H3Coordinate(lat: 37.8044, lng: -122.2712)

let sfIndex = H3Index(coordinate: sf, resolution: 9)
let oaklandIndex = H3Index(coordinate: oakland, resolution: 9)

let distance = sfIndex.distance(to: oaklandIndex)
print("   SF: \(sf.lat), \(sf.lng)")
print("   Oakland: \(oakland.lat), \(oakland.lng)")
let distStr = "\(distance ?? -1)"
print("   Grid distance: \(distStr) cell hops")
print()

print("2. Grid line between two locations")
if let line = sfIndex.gridLine(to: oaklandIndex) {
    let lineCount = "\(line.count)"
    let firstDesc = "\(line.first?.description ?? "nil")"
    let lastDesc = "\(line.last?.description ?? "nil")"
    print("   Line contains \(lineCount) cells")
    print("   First: \(firstDesc)")
    print("   Last: \(lastDesc)")
}
print()

print("3. Neighbor detection")
let neighbors = sfIndex.kRing(k: 1)
if let firstNeighbor = neighbors.first(where: { $0 != sfIndex }) {
    print("   SF is neighbor of first neighbor: \(sfIndex.isNeighbor(of: firstNeighbor))")
    print("   SF is neighbor of Oakland: \(sfIndex.isNeighbor(of: oaklandIndex))")
}
print()

print("4. Cell edges")
let edges = sfIndex.edges()
print("   Edge count: \(edges.count)")
for (i, edge) in edges.prefix(2).enumerated() {
    print("   Edge \(i): \(edge)")
    print("      Origin: \(edge.origin)")
    print("      Destination: \(edge.destination)")
    print("      Boundary vertices: \(edge.boundary().count)")
}
print()

print("5. Create edge between neighboring cells")
if let firstNeighbor = neighbors.first(where: { $0 != sfIndex }) {
    if let edge = H3Edge(from: sfIndex, to: firstNeighbor) {
        print("   Created edge: \(edge)")
    }
}
print()

print("6. Polyfill - fill polygon with H3 cells")
let exterior: [H3Coordinate] = [
    H3Coordinate(lat: 37.7749, lng: -122.4194),
    H3Coordinate(lat: 37.8049, lng: -122.4194),
    H3Coordinate(lat: 37.8049, lng: -122.3894),
    H3Coordinate(lat: 37.7749, lng: -122.3894),
]

let polygon = H3GeoPolygon(exterior: exterior)
let cellsRes7 = polygon.fill(resolution: 7)
let cellsRes9 = polygon.fill(resolution: 9)

print("   Resolution 7: \(cellsRes7.count) cells")
print("   Resolution 9: \(cellsRes9.count) cells")
print()

print("7. Polyfill with holes")
let hole: [H3Coordinate] = [
    H3Coordinate(lat: 37.7879, lng: -122.4124),
    H3Coordinate(lat: 37.7929, lng: -122.4124),
    H3Coordinate(lat: 37.7929, lng: -122.4024),
    H3Coordinate(lat: 37.7879, lng: -122.4024),
]
let polygonWithHole = H3GeoPolygon(exterior: exterior, holes: [hole])
let cellsWithHole = polygonWithHole.fill(resolution: 9)

print("   Without hole: \(cellsRes9.count) cells")
print("   With hole: \(cellsWithHole.count) cells")
print("   Hole excluded: \(cellsRes9.count - cellsWithHole.count) cells")
print()

print("8. Compact and uncompact cells")
let parentCell = H3Index(coordinate: sf, resolution: 4)
let childrenCells = parentCell.children(at: 5)

print("   Parent at res 4: \(parentCell)")
print("   Children at res 5: \(childrenCells.count) cells")

if let compacted = H3Index.compact(childrenCells) {
    print("   Compacted: \(compacted.count) cells")
    print("   Compacted index: \(compacted.first?.description ?? "nil")")
    
    if let uncompacted = H3Index.uncompact(compacted, resolution: 5) {
        print("   Uncompacted: \(uncompacted.count) cells")
    }
}
print()

print("9. kRingDistances - get cells with their distances")
let results = sfIndex.kRingDistances(k: 2)
let distanceCounts = Dictionary(grouping: results, by: { $0.distance })
for dist in 0...2 {
    let count = distanceCounts[dist]?.count ?? 0
    print("   Distance \(dist): \(count) cells")
}
print()

print("10. HexRing - hollow ring at exact distance")
if let ring = sfIndex.hexRing(k: 2) {
    print("   HexRing at k=2: \(ring.count) cells")
}
print()

print("11. Icosahedron faces")
let faces = sfIndex.faces()
print("   Faces: \(faces)")
print()

print("=== Done ===")
