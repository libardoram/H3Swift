import H3

print("=== H3 Basic Examples ===\n")

let sf = H3Coordinate(lat: 37.7749, lng: -122.4194)

print("1. Convert coordinate to H3 index")
let index = H3Index(coordinate: sf, resolution: 9)
print("   Coordinate: \(sf.lat), \(sf.lng)")
print("   H3 Index: \(index)")
print("   Resolution: \(index.resolution)")
print("   Is Valid: \(index.isValid)")
print()

print("2. Get cell center coordinate")
let center = index.coordinate
print("   Center: \(center.lat), \(center.lng)")
print()

print("3. Get cell boundary")
let boundary = index.boundary()
print("   Vertices: \(boundary.count)")
for (i, coord) in boundary.enumerated() {
    print("   \(i): \(coord.lat), \(coord.lng)")
}
print()

print("4. Traverse neighbors (k-ring)")
let k1 = index.kRing(k: 1)
let k2 = index.kRing(k: 2)
print("   k=1: \(k1.count) cells (self + 6 neighbors)")
print("   k=2: \(k2.count) cells")
print()

print("5. Navigate hierarchy")
let parent = index.parent(at: 5)
let children = index.children(at: 10)
print("   Resolution 9 -> Parent at res 5: \(parent?.description ?? "nil")")
print("   Resolution 9 -> Children at res 10: \(children.count) cells")
print("   Direct parent: \(index.directParent?.description ?? "nil")")
print("   Direct center child: \(index.directCenterChild?.description ?? "nil")")
print()

print("6. Check cell properties")
print("   Base cell: \(index.baseCell)")
print("   Is pentagon: \(index.isPentagon)")
print("   Is Class III (odd res): \(index.isResClassIII)")
print()

print("7. Resolution statistics")
for res in [0, 3, 6, 9] {
    let area = H3Index.hexArea(resolution: res, unit: .km2)
    let edge = H3Index.edgeLength(resolution: res, unit: .km)
    let count = H3Index.cellCount(resolution: res)
    let areaStr = "\(area)"
    let edgeStr = "\(edge)"
    print("   Res \(res): \(areaStr) km², edge \(edgeStr) km, \(count) cells")
}
print()

print("8. Get all pentagons at resolution 3")
let pentagons = H3Index.pentagons(resolution: 3)
print("   Count: \(pentagons.count)")
print("   First: \(pentagons.first?.description ?? "nil")")
print()

print("9. Get all resolution-0 cells")
let res0 = H3Index.res0Cells()
print("   Count: \(res0.count)")
print()

print("=== Done ===")
