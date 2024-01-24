//
//  Bird_Widget.swift
//  Bird Widget
//
//  Created by Kenny Barone on 1/18/24.
//

import WidgetKit
import SwiftUI
import CoreLocation

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SightingEntry {
        SightingEntry(date: Date(), city: "", sightingData: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SightingEntry) -> ()) {
        // TODO: add sample data
        let entry = SightingEntry(date: Date(), city: "", sightingData: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Generate a timeline consisting of up to 4/10 sightings, refresh every minute
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? Date()

        let sharedUserDefaults = UserDefaults(suiteName: AppGroupNames.defaultGroup.rawValue)
        print("defaults", sharedUserDefaults?.dictionaryRepresentation())
        let latitude = sharedUserDefaults?.object(forKey: "latitude") as? Double ?? 0
        let longitude = sharedUserDefaults?.object(forKey: "longitude") as? Double ?? 0
        let city = sharedUserDefaults?.object(forKey: "city") as? String ?? ""
        let currentRadius = sharedUserDefaults?.object(forKey: "radius") as? Double ?? 1

        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        let ebirdservice = EBirdService()
        let maxResults = context.family == .systemMedium ? 4 : 10

        Task {
            let sightings = await ebirdservice.fetchSightings(for: currentLocation, radius: currentRadius, maxResults: maxResults, cachedSightings: [], widgetFetch: true)
            let entry = SightingEntry(date: currentDate, city: city, sightingData: sightings)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct SightingEntry: TimelineEntry {
    let date: Date
    let city: String
    let sightingData: [BirdSighting]
}

struct Bird_WidgetEntryView: View {
    var entry: SightingEntry

    var body: some View {
        ZStack {
            Color("WidgetBackground").ignoresSafeArea()
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.city)
                    .font(Fonts.SFProRegular.font(with: 9))
                    .foregroundColor(Colors.PrimaryGray.color)
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: 0
                ) {
                    ForEach(entry.sightingData, id: \.self) { sighting in
                        CardView(imageData: sighting.imageData, name: sighting.commonName)
                            .padding(.bottom, 8)
                            .padding(.trailing, 8)
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 8))
        }
    }
}

struct CardView: View {
    let imageData: Data?
    let name: String

    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                Color.gray
                    .frame(width: 50, height: 50)
                    .cornerRadius(4)
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                } else {
                    Image("DefaultBird")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .aspectRatio(contentMode: .fit)
                }
            }

            Text(name)
                .font(Fonts.SFProMedium.font(with: 11))
                .foregroundColor(.black)
                .padding(.leading, 8)
                .padding(.trailing, 8)
        }
    }
}

struct Bird_Widget: Widget {
    let kind: String = "Bird_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Bird_WidgetEntryView(entry: entry)
            .background(Color("WidgetBackground"))
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName("Bird Widget🦤")
        .description("Keep track of bird sightings near you!")
    }
}

struct Bird_Widget_Previews: PreviewProvider {
    static var previews: some View {
        Bird_WidgetEntryView(entry: SightingEntry(date: Date(), city: "", sightingData: []))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        Bird_WidgetEntryView(entry: SightingEntry(date: Date(), city: "", sightingData: []))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
