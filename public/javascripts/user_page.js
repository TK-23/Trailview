 window.onload = function() { initialize();};

  function initialize() {

    all_tracks = <%= @tracks_geoJSON %>;

    map = document.getElementById("user_background_map");
    map.style.height = (window.innerHeight - 70 ) +"px";

    initialize_home_map();

  }

  function initialize_home_map() {
    var map = L.mapbox.map('user_background_map', 'examples.map-i86nkdio')
    .setView([42.25, -72], 9);

    var tracks = L.mapbox.featureLayer(all_tracks);
    tracks.addTo(map);
  }

