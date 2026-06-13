import Foundation

/// Disk-backed `ForecastCache` storing one JSON file per city.
///
/// Files are named `forecast-{city.id}.json` inside an injectable directory
/// (default: the user's caches directory). Reads are resilient: a miss or any
/// decode/IO failure returns `nil` rather than throwing, so a corrupt or
/// schema-drifted file degrades to a cache miss.
actor DiskForecastCache: ForecastCache {
    private let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// - Parameter directory: Where per-city files live. Defaults to `.cachesDirectory`.
    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            self.directory = FileManager.default
                .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func save(_ forecast: WeatherForecast) async {
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(forecast)
            try data.write(to: fileURL(forCityID: forecast.city.id), options: .atomic)
        } catch {
            // Best-effort cache: a failed write must not surface to callers.
        }
    }

    func forecast(for city: City) async -> WeatherForecast? {
        let url = fileURL(forCityID: city.id)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(WeatherForecast.self, from: data)
    }

    private func fileURL(forCityID id: Int) -> URL {
        directory.appendingPathComponent("forecast-\(id).json")
    }
}
