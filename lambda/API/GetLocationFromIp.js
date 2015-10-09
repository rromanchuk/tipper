var https = require('https');

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var ip = event.ip
    
    https.get({
        host: 'www.telize.com',
        path: '/geoip/' + ip
    }, function(response) {
        // Continuously update stream with data
        var body = '';
        response.on('data', function(d) {
            body += d;
        });
        response.on('end', function() {
            console.log(body);
            // Data reception is done, do whatever with it!
            var ipData = JSON.parse(body);
            console.log(ipData);
            var ipJSON = {"lat": ipData.latitude, "lng": ipData.longitude}
            context.done(null, ipJSON)
        });
    });
};