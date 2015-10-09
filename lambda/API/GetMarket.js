var https = require('https');


exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var qty = event.qty
    
    https.get({
        host: 'api.coinbase.com',
        path: '/v1/prices/buy?qty=' + qty
    }, function(response) {
        // Continuously update stream with data
        var body = '';
        response.on('data', function(d) {
            body += d;
        });
        response.on('end', function() {
            console.log(body);
            // Data reception is done, do whatever with it!
            var market = JSON.parse(body);
            console.log(market);
            var marketJSON = {"amount": market.total.amount, "subtotalAmount": market.subtotal.amount, "btc": market.btc.amount, "updatedAt": Math.floor(Date.now() / 1000)}
            context.done(null, marketJSON)
        });
    });
};