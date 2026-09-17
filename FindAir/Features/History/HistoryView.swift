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
    @State private var placeName = "Saved location"
    @State private var isDetectionSheetCollapsed = false

    init(record: HistoryRecord) {
        self.record = record
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                SavedLocationMap(region: region, mapError: $mapError)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()

                    if let mapError {
                        VStack(spacing: 10) {
                            Image(systemName: "map.fill")
                                .font(.title)
                            Text("Map could not be loaded")
                                .font(.headline)
                            Text(mapError)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            Text(coordinateText)
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .padding(20)
                        .background(.black.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding()
                    }

                    detectionSheet
                        .frame(maxWidth: .infinity)
                        .frame(
                            height: isDetectionSheetCollapsed
                                ? 150
                                : min(geometry.size.height * 0.45, 420),
                            alignment: .top
                        )
                        .background(Color(red: 0.035, green: 0.055, blue: 0.07))
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 34,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 34
                            )
                        )
                        .shadow(color: .black.opacity(0.45), radius: 20, y: -8)
                        .animation(.easeInOut(duration: 0.25), value: isDetectionSheetCollapsed)
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onEnded { value in
                                    if value.translation.height > 50 {
                                        isDetectionSheetCollapsed = true
                                    } else if value.translation.height < -50 {
                                        isDetectionSheetCollapsed = false
                                    }
                                }
                        )
                }
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await resolvePlaceName()
        }
    }

    private var detectionSheet: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.white.opacity(0.75))
                .frame(width: 42, height: 5)
                .padding(.top, 14)

            HStack(spacing: 14) {
                Image(systemName: "scope")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.yellow)

                Text("Detection Details")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close map")
            }
            .padding(.horizontal, 24)

            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Image(systemName: deviceIcon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text(record.device?.displayName ?? "Unknown Device")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("Found")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.yellow)
                        .clipShape(Capsule())
                }
                .padding(10)

                detailRow(icon: "clock", title: "Time", value: timeText)
                detailRow(icon: "mappin.and.ellipse", title: "Location", value: placeName)
                detailRow(icon: "wifi", title: "Signal Strength", value: "\(record.signalPercentage)%")
                Spacer(minLength: 10)
            }
            .background(Color.white.opacity(0.055))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
            
        }
        .padding(.bottom, 24)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 32)
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.75))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private func resolvePlaceName() async {
        let location = CLLocation(latitude: record.latitude, longitude: record.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return
        }
        guard let name = placemark.name ?? placemark.locality else {
            return
        }
        placeName = name
    }

    private var coordinateText: String {
        String(format: "%.5f, %.5f", record.latitude, record.longitude)
    }

    private var timeText: String {
        guard let date = record.foundAt else { return "Unknown" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private var deviceIcon: String {
        switch record.device?.category {
        case "Audio": return "airpodspro"
        case "Wearables": return "applewatch"
        case "Phones/Tablets": return "iphone"
        default: return "dot.radiowaves.left.and.right"
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


