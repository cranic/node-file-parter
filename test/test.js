file = require('../app');

hash = new file('sha1', 1024 * 1024 * 1024, 'test.txt');

hash.on('data', function(data){
	console.log('Data:', data);
});

hash.on('error', function(err){
	console.log('Error:', err);
});

hash.on('end', function(data){
	console.log('End:', data);
});
