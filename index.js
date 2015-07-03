'use strict';

var express = require('express');
var pg = require('pg').native;
var bodyParser = require('body-parser');
var _ = require('underscore');


var conString = 'postgres://osm:osm@localhost/osm';
var pgClient = new pg.Client(conString);

var app = express();

app.use(bodyParser.urlencoded({
	extended: true
}));

function findNearest(req, res, next) {
	var query = 'SELECT * from find_nearest($1, $2);';

	pgClient.query(query, [parseFloat(req.query.lat), parseFloat(req.query.lon)], function (err, result) {
		var rows = result.rows;

		var uniqIds = _.uniq(_.pluck(rows, 'id'));

		var results = {};

		_.each(uniqIds, function (val) {
			results[val] = {
				coordinates: []
			};
		});

		_.each(rows, function (el) {
			results[el.id].coordinates.push({
				latitude: el.latitude,
				longitude: el.longitude
			});

			results[el.id].name = el.name;
			results[el.id].id = el.id;
		});

		var resultsArray = _.map(uniqIds, function (val) {
			return results[val];
		});

		res.status(200).send(resultsArray);

	});
}

app.get('/nearest', findNearest);

pgClient.connect(function (err) {
	if (err) {
		console.log('Error connecting to database', err);
	} else {
		console.log('Connected to postgres database:', 'osm');
		app.listen(8080, function () {
			console.log('Listening on port 8080');
		});
	}
});