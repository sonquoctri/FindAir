import CoreData
import MapKit
import SwiftUI

public struct HistoryView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HistoryDevice.deviceName, ascending: true)],
        animation: nil
    ) private var devices: FetchedResults<HistoryDevice>
    @State private var selectedMapRecord: HistoryMapSelection?

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if devices.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 42))
                            .foregroundStyle(.gray)
                        Text("No history yet")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Devices you find will appear here.")
                            .foregroundStyle(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(devices, id: \.objectID) { device in
                                HistoryDeviceRow(device: device) { record in
                                    print("History record selected: \(record.objectID)")
                                    selectedMapRecord = HistoryMapSelection(record: record)
                                }
                            }
                        }
                        .padding(18)
                    }
                }
            }
            .navigationTitle("History")
            .fullScreenCover(item: $selectedMapRecord) { selection in
                MapView(record: selection.record)
                    .onAppear {
                        print("Map cover appeared")
                        print("MapView appeared for record: \(selection.record.objectID)")
                    }
            }
        }
    }
}

private struct HistoryMapSelection: Identifiable {
    let record: HistoryRecord
    let id: String

    init(record: HistoryRecord) {
        self.record = record
        id = record.objectID.uriRepresentation().absoluteString
    }
}

private struct HistoryDeviceRow: View {
    @ObservedObject var device: HistoryDevice
    let onSelectRecord: (HistoryRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(device.displayName)
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(device.sortedRecords, id: \.objectID) { record in
                Button {
                    print("History record pressed: \(record.objectID), hasLocation=\(record.hasLocation)")
                    if record.hasLocation {
                        onSelectRecord(record)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: record.hasLocation ? "mappin.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(record.hasLocation ? .blue : .green)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Signal \(record.signalPercentage)%")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Text(record.foundAt ?? Date(), style: .date)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        Spacer()

                        if record.hasLocation {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.gray)
                        } else {
                            Text("No location")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                }
//                .buttonStyle(.plain)
                
            }
        }
        .padding(14)
        .background(Color(red: 40 / 255, green: 40 / 255, blue: 40 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MapView: View {
    @Environment(\.dismiss) private var dismiss

    let record: HistoryRecord
    @State private var region: MKCoordinateRegion
    @State private var mapError: String?

    init(record: HistoryRecord) {
        self.record = record
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SavedLocationMap(region: region, mapError: $mapError)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)

                if let mapError {
                    VStack(spacing: 10) {
                        Image(systemName: "map.fill")
                            .font(.title)
                        Text("Map could not be loaded")
                            .font(.headline)
                        Text(mapError)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Text("\(record.latitude), \(record.longitude)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .padding(20)
                    .background(.black.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding()
                }
            }
            .navigationTitle(record.device?.displayName ?? "Device Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close map")
                }
            }
        }
    }
}

private struct SavedLocationMap: UIViewRepresentable {
    let region: MKCoordinateRegion
    @Binding var mapError: String?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.backgroundColor = .black
        mapView.delegate = context.coordinator
        mapView.preferredConfiguration = MKStandardMapConfiguration()
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.setRegion(region, animated: false)

        let annotation = MKPointAnnotation()
        annotation.coordinate = region.center
        mapView.addAnnotation(annotation)
        return mapView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(mapError: $mapError)
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = .standard
        mapView.setRegion(region, animated: false)

        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = region.center
        mapView.addAnnotation(annotation)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var mapError: Binding<String?>?

        init(mapError: Binding<String?>? = nil) {
            self.mapError = mapError
        }

        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            mapError?.wrappedValue = nil
        }

        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
            mapError?.wrappedValue = error.localizedDescription
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "SavedLocationPin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            (view as? MKMarkerAnnotationView)?.markerTintColor = .systemRed
            (view as? MKMarkerAnnotationView)?.glyphImage = UIImage(systemName: "mappin")
            return view
        }
    }
}


