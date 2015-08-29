'use strict';

var express = require('express');
var pg = require('pg').native;
var bodyParser = require('body-parser');
var _ = require('underscore');
var async = require('async');


var conString = 'postgres://osm:osm@localhost/osm';
var pgClient = new pg.Client(conString);

var app = express();

app.use(bodyParser.urlencoded({
	extended: true
}));


function findNearestWaterways(opts, cb) {
	var query = 'SELECT * from find_nearest_waterways($1, $2, $3);';

	var inset = opts.inset || 0.1;

	inset = Math.min(inset, 0.6);

	pgClient.query(query, [parseFloat(opts.lat), parseFloat(opts.lon), parseFloat(inset)], function (err, result) {

		if (err) {
			return cb(err);
		}

		cb(null, processResults(result));
	});
}

function findNearestLakes(opts, cb) {
	var query = 'SELECT * from find_nearest_lakes($1, $2, $3);';

	var inset = opts.inset || 0.1;

	inset = Math.min(inset, 0.6);

	pgClient.query(query, [parseFloat(opts.lat), parseFloat(opts.lon), parseFloat(inset)], function (err, result) {

		if (err) {
			return cb(err);
		}

		cb(null, processResults(result));
	});
}

function processResults(result, isRiver) {
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

		if (isRiver) {
			results[el.id].type = 'river';
		} else {
			results[el.id].type = 'lake';
		}

		results[el.id].name = el.the_name;
		results[el.id].id = el.id;
	});

	var resultsArray = _.map(uniqIds, function (val) {
		return results[val];
	});

	return resultsArray;
}

function nearestWaterwaysRoute(req, res) {
	findNearestWaterways(req.query, function (err, waterways) {
		var status = err ? 500 : 200;
		var data = err ? null : waterways;

		res.status(status).send(data);
	});
}

function nearestLakesRoute(req, res) {
	findNearestLakes(req.query, function (err, lakes) {
		var status = err ? 500 : 200;
		var data = err ? null : lakes;

		res.status(status).send(data);
	});
}

function nearestRoute(req, res) {
	async.parallel({
		lakes: function (cb) {
			findNearestLakes(req.query, cb);
		},
		rivers: function (cb) {
			findNearestWaterways(req.query, cb);
		}
	}, function (err, results) {
		if (err) {
			return res.status(500).end();
		} else {
			var lakes = results.lakes;
			var rivers = results.rivers;

			var waterways = rivers.concat(lakes).sort(function (x, y) {
				return x.distance - y.distance;
			});

			res.status(200).send(waterways);
		}
	});
}

app.get('/nearest/waterways', nearestWaterwaysRoute);

app.get('/nearest/waters', nearestLakesRoute);

app.get('/nearest', nearestRoute);

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