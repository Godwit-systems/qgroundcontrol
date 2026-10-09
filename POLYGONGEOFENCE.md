# Polygon geofence

A geofence is a virtual polygon the vehicle must stay inside (inclusion) or stay out of (exclusion). This build loads that polygon from a KML file in Plan View, then uploads it with the rest of the plan.

A sample boundary is already in the repo: `custom/geofence/cph-boundary.kml` (a KML `Polygon` / `LinearRing` of `longitude,latitude` pairs around Copenhagen). You can draw your own at [geojson.io](https://geojson.io), export KML, and use that file the same way.

The vehicle firmware has to support GeoFence. If it does not, Plan View says so and the insert buttons stay hidden.

## Load a boundary

1. Open **Plan View**.
2. Set the home position on the map.
3. If QGC asks for a mission template, pick **No Template**. The fence is separate from the mission items.
4. Open the **GeoFence** section in the plan editor (or switch to the GeoFence layer with the layer control at the top right of the map).
5. Under **Insert GeoFence**, click **Polygon Fence**. QGC drops a default inclusion polygon in the current map view.
6. Leave that polygon selected for edit. The map toolbar shows **Load KML/SHP...**. Click it and choose the KML file. The file replaces the default vertices.
7. In **Polygon Fences**, leave **Inclusion** checked when the vehicle must stay inside the polygon. Clear it for an exclusion zone (the vehicle must stay outside).
8. Set any fence parameters in that same panel, such as the breach action, if the firmware exposes them.
9. Save the plan, then click **Upload**. The geofence goes up with the mission.
10. Switch to **Fly View**.

You can still edit the shape on the map after import: drag the filled vertices, and click an unfilled midpoint to add a vertex. **Del** on that polygon row removes it.
