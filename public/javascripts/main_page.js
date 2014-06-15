  window.onload = function() { initialize();};

  function initialize() {

    map = document.getElementById("background_map");
    map.style.height = (window.innerHeight - 70 ) +"px";

    initialize_home_map();

  }

  function initialize_home_map() {
    var map = L.mapbox.map('background_map', 'examples.map-i86nkdio')
    .setView([42.25, -72], 9);
  }



