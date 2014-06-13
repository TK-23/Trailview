  window.onload = function() { initialize();};

  function initialize() {

    map = document.getElementById("user_background_map");
    map.style.height = (window.innerHeight - 20 ) +"px";

    initialize_home_map();

  }

  function initialize_home_map() {
    var map = L.mapbox.map('user_background_map', 'examples.map-i86nkdio')
    .setView([42.25, -72], 9);
  }



