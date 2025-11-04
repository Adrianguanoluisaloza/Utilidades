package com.mycompany.delivery.api.services;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class GoogleMapsService {
    private static final String API_KEY = System.getenv("GOOGLE_MAPS_API_KEY");
    private static final String GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json";
    private final HttpClient httpClient;

    public GoogleMapsService() {
    this.httpClient = HttpClient.newBuilder()
        .version(HttpClient.Version.HTTP_2)
        .connectTimeout(Duration.ofSeconds(10))
        .build();
    }

    public String geocodeAddress(String address) {
        if (API_KEY == null || API_KEY.isBlank()) {
            System.err.println("[WARNING] GOOGLE_MAPS_API_KEY no configurada, usando coordenadas por defecto de Esmeraldas");
            // Fallback: coordenadas de Esmeraldas, Ecuador
            return "{\"results\":[{\"geometry\":{\"location\":{\"lat\":0.9637,\"lng\":-79.6531}},\"formatted_address\":\"Esmeraldas, Ecuador\"}],\"status\":\"OK\"}";
        }
        String url = GEOCODE_URL + "?address=" + address.replace(" ", "+") + "&key=" + API_KEY;
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .GET()
                .build();
        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                return response.body();
            } else {
                System.err.println("Error en la API de Google Maps: " + response.statusCode() + " - " + response.body());
                return null;
            }
        } catch (IOException | InterruptedException e) {
            System.err.println("Excepción al llamar a la API de Google Maps: " + e.getMessage());
            Thread.currentThread().interrupt();
            return null;
        }
    }
}
