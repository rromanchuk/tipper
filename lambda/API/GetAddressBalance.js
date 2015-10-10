var https = require('https');

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var address = event.address
    
    https.get({
        host: 'bitcoin.toshi.io',
        path: '/api/v0/addresses/' + address
    }, function(response) {
        // Continuously update stream with data
        var body = '';
        response.on('data', function(d) {
            body += d;
        });
        response.on('end', function() {
            console.log(body);
            // Data reception is done, do whatever with it!
            var addressData = JSON.parse(body);
            console.log(addressData);
            var addressJSON = {"balance": addressData.balance}
            context.done(null, addressJSON)
        });
    });
};